import tippy from 'tippy.js';
import Vue, { nextTick } from 'vue';
import { Plugin as MockPMPlugin } from '@tiptap/pm/state';
import Suggestions from '~/content_editor/extensions/suggestions';

import { createTestEditor } from '../test_utils';

jest.mock('@tiptap/suggestion', () => {
  const captured = [];
  const mock = (config) => {
    captured.push(config);
    return new MockPMPlugin({ props: { items: config.items } });
  };
  mock.getCaptured = () => captured;
  mock.findSuggestionMatch = jest.requireActual('@tiptap/suggestion').findSuggestionMatch;
  return mock;
});

jest.mock('tippy.js');

describe('content_editor/extensions/suggestions', () => {
  let editor;
  let searchMock;

  const buildEditorWithExtension = (autocompleteResults, { serialized = '/command' } = {}) => {
    searchMock = jest.fn().mockImplementation(() => Promise.resolve(autocompleteResults));

    const mockAutocompleteHelper = {
      getDataSource: jest.fn().mockReturnValue({ search: searchMock }),
    };

    const serializer = { serialize: jest.fn().mockReturnValue(serialized) };

    editor = createTestEditor({
      extensions: [
        Suggestions.configure({ autocompleteHelper: mockAutocompleteHelper, serializer }),
      ],
    });
  };

  const mockEditorCtx = (references = []) => ({
    state: {
      doc: {
        slice: jest.fn().mockReturnValue({ content: {} }),
        descendants: (callback) => references.forEach(callback),
      },
      selection: { to: 10 },
    },
    isActive: jest.fn().mockReturnValue(false),
  });

  const getItemsForChar = (char) => {
    const SuggestionMock = jest.requireMock('@tiptap/suggestion');
    const config = SuggestionMock.getCaptured().find((c) => c.char === char);
    if (!config) throw new Error(`Suggestion config for "${char}" not captured`);
    return config.items;
  };

  const getSlashItems = () => getItemsForChar('/');
  const getAtItems = () => getItemsForChar('@');

  const userReference = (text) => ({
    type: { name: 'reference' },
    attrs: { referenceType: 'user', text },
  });

  afterEach(() => {
    const SuggestionMock = jest.requireMock('@tiptap/suggestion');
    SuggestionMock.getCaptured().length = 0;

    editor.destroy();
  });

  describe('quick actions alphabetical sorting', () => {
    it('sorts quick action commands alphabetically by name', async () => {
      buildEditorWithExtension([
        { name: 'zebra', description: 'Zebra command' },
        { name: 'alpha', description: 'Alpha command' },
        { name: 'beta', description: 'Beta command' },
      ]);

      const items = getSlashItems();
      const result = await items({ query: '', editor: mockEditorCtx() });

      expect(result.map((r) => r.name)).toEqual(['alpha', 'beta', 'zebra']);
    });

    it('places null/undefined names at the end, preserving order among them', async () => {
      buildEditorWithExtension([
        { name: 'zebra', description: 'Zebra command' },
        { name: null, description: 'Null command' },
        { name: 'alpha', description: 'Alpha command' },
        { name: undefined, description: 'Undefined command' },
      ]);

      const items = getSlashItems();
      const result = await items({ query: '', editor: mockEditorCtx() });

      expect(result.map((r) => r.name)).toEqual(['alpha', 'zebra', null, undefined]);
    });

    it('does not re-sort when query is present; preserves data source order', async () => {
      buildEditorWithExtension([
        { name: 'beta', description: 'Beta command' },
        { name: 'alpha', description: 'Alpha command' },
        { name: 'zebra', description: 'Zebra command' },
      ]);

      const items = getSlashItems();
      const result = await items({ query: 'a', editor: mockEditorCtx() });

      expect(result.map((r) => r.name)).toEqual(['beta', 'alpha', 'zebra']);
    });
  });

  describe('prioritizing already-mentioned users', () => {
    it('passes usernames mentioned in the document to the data source for member quick actions', async () => {
      buildEditorWithExtension([], { serialized: '/request_review @' });

      const items = getAtItems();
      await items({
        query: '',
        editor: mockEditorCtx([
          userReference('@deloras'),
          { type: { name: 'reference' }, attrs: { referenceType: 'issue', text: '#1' } },
          userReference('@arlie'),
        ]),
      });

      expect(searchMock).toHaveBeenCalledWith('/request_review', '', {
        prioritizeUsernames: ['deloras', 'arlie'],
      });
    });

    it('does not collect mentions for a plain @ outside a member quick action', async () => {
      buildEditorWithExtension([], { serialized: '@' });

      const items = getAtItems();
      await items({ query: '', editor: mockEditorCtx([userReference('@deloras')]) });

      expect(searchMock).toHaveBeenCalledWith(undefined, '', { prioritizeUsernames: [] });
    });

    it('floats the mentioned user to the top while keeping the rest alphabetical', async () => {
      buildEditorWithExtension(
        [
          { username: 'zelda', name: 'Zelda' },
          { username: 'deloras', name: 'Jimmy Stanton' },
          { username: 'aaron', name: 'Aaron' },
        ],
        { serialized: '/request_review @' },
      );

      const items = getAtItems();
      const result = await items({
        query: '',
        editor: mockEditorCtx([userReference('@deloras')]),
      });

      expect(result.map((r) => r.username)).toEqual(['deloras', 'aaron', 'zelda']);
    });
  });

  describe('emoji autocomplete preference', () => {
    const capturedChars = () =>
      jest
        .requireMock('@tiptap/suggestion')
        .getCaptured()
        .map((c) => c.char);

    it('registers the emoji suggestion when the preference is enabled', () => {
      window.gon = { emoji_autocomplete_enabled: true };
      buildEditorWithExtension([]);

      expect(capturedChars()).toContain(':');
    });

    it('registers the emoji suggestion when the preference is unset', () => {
      window.gon = {};
      buildEditorWithExtension([]);

      expect(capturedChars()).toContain(':');
    });

    it('does not register the emoji suggestion when the preference is disabled', () => {
      window.gon = { emoji_autocomplete_enabled: false };
      buildEditorWithExtension([]);

      expect(capturedChars()).not.toContain(':');
    });

    it('leaves other suggestions registered when emoji autocomplete is disabled', () => {
      window.gon = { emoji_autocomplete_enabled: false };
      buildEditorWithExtension([]);

      const chars = capturedChars();
      expect(chars).toContain('@');
      expect(chars).toContain('/');
      expect(chars).not.toContain(':');
    });
  });

  describe('trigger configuration', () => {
    const capturedConfigs = () => jest.requireMock('@tiptap/suggestion').getCaptured();

    beforeEach(() => {
      window.gon = { emoji_autocomplete_enabled: true };
      buildEditorWithExtension([]);
    });

    it('registers every trigger', () => {
      expect(capturedConfigs().map((c) => c.char)).toEqual([
        '@',
        '#',
        '[issue:',
        '[work_item:',
        '$',
        '~',
        '&',
        '[epic:',
        '!',
        '[vulnerability:',
        '*iteration:',
        '"',
        '%',
        ':',
        '[[',
        '/',
      ]);
    });

    it('lets every query run across spaces', () => {
      expect(capturedConfigs().every((c) => c.allowSpaces)).toBe(true);
    });

    it('narrows the match on a leading space for every trigger', () => {
      expect(capturedConfigs().every((c) => c.findSuggestionMatch)).toBe(true);
    });

    describe('the trigger match', () => {
      const matchTrigger = (char, text) =>
        capturedConfigs()
          .find((c) => c.char === char)
          .findSuggestionMatch({
            char,
            allowSpaces: true,
            allowToIncludeChar: false,
            allowedPrefixes: [' '],
            startOfLine: false,
            $position: { pos: text.length + 1, nodeBefore: { isText: true, text } },
          });

      it.each`
        description                        | char   | text                 | query
        ${'the colon on its own'}          | ${':'} | ${':'}               | ${''}
        ${'a name being typed'}            | ${':'} | ${':smil'}           | ${'smil'}
        ${'a name followed by a space'}    | ${':'} | ${':smiling '}       | ${'smiling '}
        ${'a name with a space inside it'} | ${':'} | ${'a :smiling f'}    | ${'smiling f'}
        ${'a title being typed'}           | ${'!'} | ${'!Fix the'}        | ${'Fix the'}
        ${'a title with a space after it'} | ${'!'} | ${'!Fix the '}       | ${'Fix the '}
        ${'an issue title with spaces'}    | ${'#'} | ${'#login page bug'} | ${'login page bug'}
      `('keeps searching for $description', ({ char, text, query }) => {
        expect(matchTrigger(char, text)).toMatchObject({ query });
      });

      it.each`
        description                              | char   | text
        ${'a space right after the colon'}       | ${':'} | ${': '}
        ${'French spacing before a word'}        | ${':'} | ${'Statut : suite'}
        ${'a space right after the bang'}        | ${'!'} | ${'! '}
        ${'French spacing after an exclamation'} | ${'!'} | ${'Bonjour ! Comment'}
        ${'a space right after the tilde'}       | ${'~'} | ${'~ '}
        ${'a space right after the hash'}        | ${'#'} | ${'# '}
      `('stops searching on $description', ({ char, text }) => {
        expect(matchTrigger(char, text)).toBeNull();
      });
    });

    it('only requires quick actions to start the line', () => {
      const startOfLine = capturedConfigs()
        .filter((c) => c.startOfLine)
        .map((c) => c.char);

      expect(startOfLine).toEqual(['/']);
    });
  });

  describe('popup keyboard handling', () => {
    let handlers;
    let popup;
    let tippyOptions;
    let command;
    let editorDom;

    const emojiItem = {
      emoji: {
        name: 'smile',
        e: '😄',
        d: 'smiling face with open mouth and smiling eyes',
        u: '6.0',
      },
      fieldValue: 'smile',
    };

    const keyDownEvent = (key) => {
      const event = new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true });
      jest.spyOn(event, 'stopPropagation');
      return event;
    };

    // Builds the popup with its items already known. The live plugin passes the loaded
    // items through onStart, which updates the same props on the rendered component.
    const openPopup = async ({ query, items }) => {
      handlers.onBeforeStart({
        editor: { view: { dom: editorDom } },
        clientRect: () => new DOMRect(0, 0, 100, 20),
        items,
        query,
        command,
      });
      await nextTick();
    };

    beforeAll(() => {
      // The dropdown renders emoji through the <gl-emoji> custom element, which is not
      // installed in jsdom; register a plain stand-in so Vue does not warn about it.
      Vue.component('GlEmoji', { render: (h) => h('span') });
    });

    beforeEach(() => {
      popup = { setProps: jest.fn(), destroy: jest.fn(), hide: jest.fn() };
      tippy.mockImplementation((_, options) => {
        tippyOptions = options;
        return [popup];
      });
      command = jest.fn();
      editorDom = document.createElement('div');

      buildEditorWithExtension([]);

      const SuggestionMock = jest.requireMock('@tiptap/suggestion');
      handlers = SuggestionMock.getCaptured()
        .find((c) => c.char === ':')
        .render();
    });

    afterEach(() => {
      handlers.onExit();
    });

    it('renders the dropdown component as the popup content', async () => {
      await openPopup({ query: '', items: [emojiItem] });

      expect(tippyOptions.content.classList).toContain('content-editor-suggestions-dropdown');
    });

    describe('Escape', () => {
      it('hides the popup and stops the key from reaching the surrounding page', async () => {
        await openPopup({ query: '', items: [emojiItem] });
        const event = keyDownEvent('Escape');

        expect(handlers.onKeyDown({ event })).toBe(true);
        expect(popup.hide).toHaveBeenCalledTimes(1);
        expect(event.stopPropagation).toHaveBeenCalledTimes(1);
      });

      it('lets a second Escape through once the popup is hidden', async () => {
        await openPopup({ query: '', items: [emojiItem] });
        handlers.onKeyDown({ event: keyDownEvent('Escape') });
        tippyOptions.onHide();

        const event = keyDownEvent('Escape');

        expect(handlers.onKeyDown({ event })).toBe(false);
        expect(event.stopPropagation).not.toHaveBeenCalled();
      });
    });

    describe.each(['Enter', 'Tab'])('%s', (key) => {
      it('lets the key through and hides the popup while no item is highlighted', async () => {
        await openPopup({ query: '', items: [emojiItem] });
        const event = keyDownEvent(key);

        expect(handlers.onKeyDown({ event })).toBe(false);
        expect(command).not.toHaveBeenCalled();
        expect(popup.hide).toHaveBeenCalledTimes(1);
        expect(event.stopPropagation).not.toHaveBeenCalled();
      });

      it('inserts the highlighted item when the query matched', async () => {
        await openPopup({ query: 'smi', items: [emojiItem] });
        const event = keyDownEvent(key);

        expect(handlers.onKeyDown({ event })).toBe(true);
        expect(command).toHaveBeenCalledWith(
          expect.objectContaining({ text: '😄', name: 'smile' }),
        );
        expect(popup.hide).not.toHaveBeenCalled();
      });
    });

    it('ignores every key once the popup is hidden', async () => {
      await openPopup({ query: 'smi', items: [emojiItem] });
      tippyOptions.onHide();

      expect(handlers.onKeyDown({ event: keyDownEvent('Enter') })).toBe(false);
      expect(command).not.toHaveBeenCalled();
    });
  });

  describe('popup positioning', () => {
    it('tippy menu keyboard navigation prevents page scrolling on smaller viewports', () => {
      tippy.mockReturnValue([{ setProps: jest.fn(), destroy: jest.fn(), hide: jest.fn() }]);

      buildEditorWithExtension([]);

      const SuggestionMock = jest.requireMock('@tiptap/suggestion');
      const config = SuggestionMock.getCaptured().find((c) => c.char === '/');
      const handlers = config.render();

      handlers.onBeforeStart({
        editor: { view: { dom: document.createElement('div') } },
        clientRect: () => new DOMRect(0, 0, 100, 20),
        items: [],
        command: jest.fn(),
      });

      const tippyConfig = tippy.mock.calls[0][1];

      expect(tippyConfig).toMatchObject({
        placement: 'bottom-start',
        popperOptions: {
          modifiers: expect.arrayContaining([
            expect.objectContaining({
              name: 'flip',
              options: { fallbackPlacements: ['top-start'] },
            }),
            expect.objectContaining({
              name: 'preventOverflow',
              options: { boundary: 'clippingParents' },
            }),
          ]),
        },
      });
    });
  });
});
