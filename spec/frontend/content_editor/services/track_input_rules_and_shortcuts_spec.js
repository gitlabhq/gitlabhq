import { BulletList } from '@tiptap/extension-bullet-list';
import { CodeBlockLowlight } from '@tiptap/extension-code-block-lowlight';
import { Document } from '@tiptap/extension-document';
import { Heading } from '@tiptap/extension-heading';
import { ListItem } from '@tiptap/extension-list-item';
import { Paragraph } from '@tiptap/extension-paragraph';
import { Text } from '@tiptap/extension-text';
import { Editor } from '@tiptap/vue-2';
import { mockTracking } from 'helpers/tracking_helper';
import {
  KEYBOARD_SHORTCUT_TRACKING_ACTION,
  INPUT_RULE_TRACKING_ACTION,
  CONTENT_EDITOR_TRACKING_LABEL,
} from '~/content_editor/constants';
import trackInputRulesAndShortcuts from '~/content_editor/services/track_input_rules_and_shortcuts';
import { ENTER_KEY, BACKSPACE_KEY } from '~/lib/utils/keys';

describe('content_editor/services/track_input_rules_and_shortcuts', () => {
  let trackingSpy;
  let editor;
  let trackedExtensions;
  const HEADING_TEXT = 'Heading text';
  const extensions = [Document, Paragraph, Text, Heading, CodeBlockLowlight, BulletList, ListItem];

  beforeEach(() => {
    trackingSpy = mockTracking(undefined, null, jest.spyOn);
  });

  describe('given the heading extension is instrumented', () => {
    beforeEach(() => {
      trackedExtensions = extensions.map(trackInputRulesAndShortcuts);
      editor = new Editor({
        extensions: extensions.map(trackInputRulesAndShortcuts),
      });
    });

    it('does not remove existing keyboard shortcuts', () => {
      extensions.forEach((extension, index) => {
        const originalShortcuts = Object.keys(extension.addKeyboardShortcuts?.() || {});
        const trackedShortcuts = Object.keys(
          trackedExtensions[index].addKeyboardShortcuts?.() || {},
        );

        expect(originalShortcuts).toEqual(trackedShortcuts);
      });
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
