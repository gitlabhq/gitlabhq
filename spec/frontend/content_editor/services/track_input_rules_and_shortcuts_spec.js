import { mockTracking } from 'helpers/tracking_helper';
import {
  KEYBOARD_SHORTCUT_TRACKING_ACTION,
  INPUT_RULE_TRACKING_ACTION,
  CONTENT_EDITOR_TRACKING_LABEL,
} from '~/content_editor/constants';
import BulletList from '~/content_editor/extensions/bullet_list';
import CodeBlockLowlight from '~/content_editor/extensions/code_block_highlight';
import Heading from '~/content_editor/extensions/heading';
import ListItem from '~/content_editor/extensions/list_item';
import trackInputRulesAndShortcuts from '~/content_editor/services/track_input_rules_and_shortcuts';
import { ENTER_KEY, BACKSPACE_KEY } from '~/lib/utils/keys';
import { createTestEditor, triggerNodeInputRule } from '../test_utils';

describe('content_editor/services/track_input_rules_and_shortcuts', () => {
  let trackingSpy;
  let editor;
  let trackedExtensions;
  const HEADING_TEXT = 'Heading text';
  const extensions = [Heading, CodeBlockLowlight, BulletList, ListItem];

  beforeEach(() => {
    trackingSpy = mockTracking(undefined, null, jest.spyOn);
  });

  describe('given the heading extension is instrumented', () => {
    beforeEach(() => {
      trackedExtensions = extensions.map(trackInputRulesAndShortcuts);
      editor = createTestEditor({
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
      it('sends a tracking event indicating that a heading was created using an input rule', () => {
        const shortcuts = Heading.parent.config.addKeyboardShortcuts.call(Heading);
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
      it('sends a tracking event indicating that a heading was created using an input rule', () => {
        const nodeName = Heading.name;
        triggerNodeInputRule({ tiptapEditor: editor, inputRuleText: '## ' });
        expect(trackingSpy).toHaveBeenCalledWith(undefined, INPUT_RULE_TRACKING_ACTION, {
          label: CONTENT_EDITOR_TRACKING_LABEL,
          property: `${nodeName}`,
        });
      });
    });
  });
});
