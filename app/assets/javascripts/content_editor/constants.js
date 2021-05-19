import { s__ } from '~/locale';

export const PROVIDE_SERIALIZER_OR_RENDERER_ERROR = s__(
  'ContentEditor|You have to provide a renderMarkdown function or a custom serializer',
);

export const CONTENT_EDITOR_TRACKING_LABEL = 'content_editor';
export const TOOLBAR_CONTROL_TRACKING_ACTION = 'execute_toolbar_control';
export const KEYBOARD_SHORTCUT_TRACKING_ACTION = 'execute_keyboard_shortcut';
export const INPUT_RULE_TRACKING_ACTION = 'execute_input_rule';
