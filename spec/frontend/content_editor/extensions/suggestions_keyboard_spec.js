import tippy from 'tippy.js';
import Vue, { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import Suggestions from '~/content_editor/extensions/suggestions';
import Emoji from '~/content_editor/extensions/emoji';
import Reference from '~/content_editor/extensions/reference';
import ReferenceLabel from '~/content_editor/extensions/reference_label';
import Link from '~/content_editor/extensions/link';
import { createTestEditor, triggerKeyboardInput } from '../test_utils';

jest.mock('tippy.js');

const EMOJI = [
  { emoji: { name: 'grinning', e: '😀', d: 'grinning face', u: '6.1' }, fieldValue: 'grinning' },
  {
    emoji: { name: 'smile', e: '😄', d: 'smiling face with open mouth', u: '6.0' },
    fieldValue: 'smile',
  },
  {
    emoji: { name: 'ok_woman', e: '🙆', d: 'person gesturing ok', u: '6.0' },
    fieldValue: 'ok_woman',
  },
];
const USERS = [{ username: 'rosie', name: 'Rosie Rivers' }];
const LABELS = [{ title: 'UX Paper Cuts', color: '#6699cc' }];
const MILESTONES = [{ title: 'Sprint 19.5 planning' }];
const COMMANDS = [{ name: 'label', description: 'Add labels', params: ['~label1 ~"label 2"'] }];

const includes = (haystack, query) => haystack.toLowerCase().includes(query.toLowerCase());

const search = (referenceType, query) => {
  switch (referenceType) {
    case 'emoji':
      return EMOJI.filter(
        (i) => !query || includes(i.emoji.name, query) || includes(i.emoji.d, query),
      );
    case 'user':
      return USERS.filter((i) => !query || includes(i.username, query));
    case 'label':
      return LABELS.filter((i) => !query || includes(i.title, query));
    case 'milestone':
      return MILESTONES.filter((i) => !query || includes(i.title, query));
    case 'command':
      return COMMANDS.filter((i) => !query || includes(i.name, query));
    default:
      return [];
  }
};

// The popup receives its items through VueRenderer.updateProps, which cannot
// mutate props under @vue/compat, so the popup never gets them. Tracked in
// https://gitlab.com/groups/gitlab-org/-/epics/6252
const describeSkipVue3 = process.env.VUE_VERSION === '3' ? describe.skip : describe;

describeSkipVue3('content_editor/extensions/suggestions keyboard handling', () => {
  let editor;
  let container;
  let popup;
  let tippyOptions;
  let parentKeydown;

  const suggestionDecoration = () => editor.view.dom.querySelector('.suggestion');
  const doc = () => editor.state.doc;
  const paragraphTexts = () => {
    const texts = [];
    doc().forEach((node) => texts.push(node.textContent));
    return texts;
  };
  const nodeNamesInDoc = () => {
    const names = [];
    doc().descendants((node) => {
      if (node.isInline && !node.isText) names.push(node.type.name);
    });
    return names;
  };

  const type = async (text) => {
    editor.commands.insertContent(text);
    await waitForPromises();
    await nextTick();
  };

  const pressKey = async (key) => {
    const captured = triggerKeyboardInput({ tiptapEditor: editor, key });
    await waitForPromises();
    await nextTick();
    return captured;
  };

  const dispatchKeydown = (key) => {
    const event = new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true });
    editor.view.dom.dispatchEvent(event);
    return event;
  };

  beforeAll(() => {
    // The dropdown renders emoji through the <gl-emoji> custom element, which is not
    // installed in jsdom; register a plain stand-in so Vue does not warn about it.
    Vue.component('GlEmoji', { render: (h) => h('span') });
  });

  beforeEach(() => {
    window.gon = { emoji_autocomplete_enabled: true };
    popup = { setProps: jest.fn(), destroy: jest.fn(), hide: jest.fn() };
    tippy.mockImplementation((_, options) => {
      tippyOptions = options;
      return [popup];
    });

    const autocompleteHelper = {
      getDataSource: (referenceType) => ({
        search: (_prefixCommand, query) => Promise.resolve(search(referenceType, query)),
      }),
    };
    const serializer = { serialize: () => '' };

    editor = createTestEditor({
      extensions: [
        Emoji,
        Reference.configure({ assetResolver: { resolveReference: () => Promise.resolve({}) } }),
        ReferenceLabel,
        Link,
        Suggestions.configure({ autocompleteHelper, serializer }),
      ],
    });

    container = document.createElement('div');
    document.body.appendChild(container);
    container.appendChild(editor.options.element);
    parentKeydown = jest.fn();
    container.addEventListener('keydown', parentKeydown);
  });

  afterEach(() => {
    editor.destroy();
    container.remove();
  });

  describe('emoji suggestions (":")', () => {
    it('open after a colon typed after a space', async () => {
      await type('Steps :');

      expect(suggestionDecoration()).not.toBeNull();
      expect(tippy).toHaveBeenCalledTimes(1);
    });

    it('let Enter insert a new paragraph while no emoji is highlighted', async () => {
      await type('Steps :');

      await pressKey('Enter');

      expect(paragraphTexts()).toEqual(['Steps :', '']);
      expect(nodeNamesInDoc()).toEqual([]);
      expect(suggestionDecoration()).toBeNull();
    });

    it('let Tab through and hide the popup while no emoji is highlighted', async () => {
      await type('Steps :');

      const captured = await pressKey('Tab');

      expect(captured).toBe(false);
      expect(paragraphTexts()).toEqual(['Steps :']);
      expect(popup.hide).toHaveBeenCalledTimes(1);
    });

    it('insert the highlighted emoji on Enter once the query matches', async () => {
      await type('Steps :smi');

      await pressKey('Enter');

      expect(nodeNamesInDoc()).toEqual(['emoji']);
      expect(doc().firstChild.textContent).toBe('Steps  ');
      expect(paragraphTexts()).toHaveLength(1);
    });

    it.each([' ', ' ok'])(
      'close at the first space so the rest of the sentence is not a query (typed "%s")',
      async (typed) => {
        await type('Statut :');
        expect(suggestionDecoration()).not.toBeNull();

        await type(typed);

        expect(suggestionDecoration()).toBeNull();
        expect(popup.destroy).toHaveBeenCalled();
      },
    );

    it.each(['Statut : ', 'Statut : ok'])(
      'let Enter insert a new paragraph after "%s"',
      async (typed) => {
        await type(typed);

        await pressKey('Enter');

        expect(paragraphTexts()).toEqual([typed, '']);
        expect(nodeNamesInDoc()).toEqual([]);
      },
    );

    it.each(['See https://gitlab.com', 'Meeting at 10:30'])(
      'do not open for a colon inside "%s"',
      async (text) => {
        await type(text);

        expect(suggestionDecoration()).toBeNull();
        expect(tippy).not.toHaveBeenCalled();
      },
    );
  });

  describe('Escape', () => {
    it('hides the popup and does not reach the elements around the editor', async () => {
      await type('Draft :');

      const event = dispatchKeydown('Escape');

      expect(popup.hide).toHaveBeenCalledTimes(1);
      expect(event.defaultPrevented).toBe(true);
      expect(parentKeydown).not.toHaveBeenCalled();
      expect(paragraphTexts()).toEqual(['Draft :']);
    });

    it('reaches the elements around the editor once the popup is hidden', async () => {
      await type('Draft :');
      dispatchKeydown('Escape');
      tippyOptions.onHide();

      dispatchKeydown('Escape');

      expect(parentKeydown).toHaveBeenCalledTimes(1);
    });

    it('reaches the elements around the editor when no popup is open', async () => {
      await type('Draft');

      dispatchKeydown('Escape');

      expect(parentKeydown).toHaveBeenCalledTimes(1);
    });
  });

  describe('other triggers', () => {
    it.each`
      trigger | typed           | nodeName
      ${'@'}  | ${'cc @ros'}    | ${'reference'}
      ${'~'}  | ${'~UX Pa'}     | ${'referenceLabel'}
      ${'%'}  | ${'%Sprint 19'} | ${'reference'}
      ${'/'}  | ${'/lab'}       | ${'reference'}
    `('$trigger: Enter inserts the first match, spaces included', async ({ typed, nodeName }) => {
      await type(typed);
      expect(suggestionDecoration()).not.toBeNull();

      await pressKey('Enter');

      expect(nodeNamesInDoc()).toEqual([nodeName]);
      expect(paragraphTexts()).toHaveLength(1);
    });

    it('@: Enter inserts a new paragraph while nothing is highlighted', async () => {
      await type('cc @');
      expect(suggestionDecoration()).not.toBeNull();

      await pressKey('Enter');

      expect(paragraphTexts()).toEqual(['cc @', '']);
      expect(nodeNamesInDoc()).toEqual([]);
    });
  });
});
