import { BulletList } from '@tiptap/extension-bullet-list';
import { CodeBlockLowlight } from '@tiptap/extension-code-block-lowlight';
import { Document } from '@tiptap/extension-document';
import { Heading } from '@tiptap/extension-heading';
import { ListItem } from '@tiptap/extension-list-item';
import { Paragraph } from '@tiptap/extension-paragraph';
import { Text } from '@tiptap/extension-text';
import { Editor, EditorContent } from '@tiptap/vue-2';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { mockTracking } from 'helpers/tracking_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import {
  KEYBOARD_SHORTCUT_TRACKING_ACTION,
  INPUT_RULE_TRACKING_ACTION,
  CONTENT_EDITOR_TRACKING_LABEL,
} from '~/content_editor/constants';
import trackInputRulesAndShortcuts from '~/content_editor/services/track_input_rules_and_shortcuts';
import { ENTER_KEY, BACKSPACE_KEY } from '~/lib/utils/keys';

describe('content_editor/services/track_input_rules_and_shortcuts', () => {
  let wrapper;
  let trackingSpy;
  let editor;
  const HEADING_TEXT = 'Heading text';

  const buildWrapper = () => {
    wrapper = extendedWrapper(
      mount(EditorContent, {
        propsData: {
          editor,
        },
      }),
    );
  };

  beforeEach(() => {
    trackingSpy = mockTracking(undefined, null, jest.spyOn);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('given the heading extension is instrumented', () => {
    beforeEach(() => {
      editor = new Editor({
        extensions: [
          Document,
          Paragraph,
          Text,
          Heading,
          CodeBlockLowlight,
          BulletList,
          ListItem,
        ].map(trackInputRulesAndShortcuts),
      });
    });

    beforeEach(async () => {
      buildWrapper();
      await nextTick();
    });

    describe('when creating a heading using an keyboard shortcut', () => {
      it('sends a tracking event indicating that a heading was created using an input rule', async () => {
        const shortcuts = Heading.config.addKeyboardShortcuts.call(Heading);
        const [firstShortcut] = Object.keys(shortcuts);
        const nodeName = Heading.name;

        editor.chain().keyboardShortcut(firstShortcut).insertContent(HEADING_TEXT).run();

        expect(trackingSpy).toHaveBeenCalledWith(undefined, KEYBOARD_SHORTCUT_TRACKING_ACTION, {
          label: CONTENT_EDITOR_TRACKING_LABEL,
          property: `${nodeName}.${firstShortcut}`,
        });
      });
    });

    it.each`
      extension                 | shortcut
      ${ListItem.name}          | ${ENTER_KEY}
      ${CodeBlockLowlight.name} | ${BACKSPACE_KEY}
    `('does not track $shortcut shortcut for $extension extension', ({ shortcut }) => {
      editor.chain().keyboardShortcut(shortcut).run();

      expect(trackingSpy).not.toHaveBeenCalled();
    });

    describe('when creating a heading using an input rule', () => {
      it('sends a tracking event indicating that a heading was created using an input rule', async () => {
        const nodeName = Heading.name;
        const { view } = editor;
        const { selection } = view.state;

        // Triggers the event handler that input rules listen to
        view.someProp('handleTextInput', (f) => f(view, selection.from, selection.to, '## '));

        editor.chain().insertContent(HEADING_TEXT).run();

        expect(trackingSpy).toHaveBeenCalledWith(undefined, INPUT_RULE_TRACKING_ACTION, {
          label: CONTENT_EDITOR_TRACKING_LABEL,
          property: `${nodeName}`,
        });
      });
    });
  });
});
