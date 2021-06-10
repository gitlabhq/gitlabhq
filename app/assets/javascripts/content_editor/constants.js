import { s__, __ } from '~/locale';

export const PROVIDE_SERIALIZER_OR_RENDERER_ERROR = s__(
  'ContentEditor|You have to provide a renderMarkdown function or a custom serializer',
);

export const CONTENT_EDITOR_TRACKING_LABEL = 'content_editor';
export const TOOLBAR_CONTROL_TRACKING_ACTION = 'execute_toolbar_control';
export const KEYBOARD_SHORTCUT_TRACKING_ACTION = 'execute_keyboard_shortcut';
export const INPUT_RULE_TRACKING_ACTION = 'execute_input_rule';

export const TEXT_STYLE_DROPDOWN_ITEMS = [
  {
    contentType: 'heading',
    commandParams: { level: 1 },
    editorCommand: 'setHeading',
    label: __('Heading 1'),
  },
  {
    contentType: 'heading',
    editorCommand: 'setHeading',
    commandParams: { level: 2 },
    label: __('Heading 2'),
  },
  {
    contentType: 'heading',
    editorCommand: 'setHeading',
    commandParams: { level: 3 },
    label: __('Heading 3'),
  },
  {
    contentType: 'heading',
    editorCommand: 'setHeading',
    commandParams: { level: 4 },
    label: __('Heading 4'),
  },
  {
    contentType: 'paragraph',
    editorCommand: 'setParagraph',
    label: __('Normal text'),
  },
];
