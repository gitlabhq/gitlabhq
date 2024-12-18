import { s__, __ } from '~/locale';

export const PROVIDE_SERIALIZER_OR_RENDERER_ERROR = s__(
  'ContentEditor|You have to provide a renderMarkdown function or a custom serializer',
);

export const CONTENT_EDITOR_TRACKING_LABEL = 'content_editor';
export const TOOLBAR_CONTROL_TRACKING_ACTION = 'execute_toolbar_control';
export const BUBBLE_MENU_TRACKING_ACTION = 'execute_bubble_menu_control';
export const KEYBOARD_SHORTCUT_TRACKING_ACTION = 'execute_keyboard_shortcut';
export const INPUT_RULE_TRACKING_ACTION = 'execute_input_rule';

export const TEXT_STYLE_DROPDOWN_ITEMS = [
  {
    contentType: 'paragraph',
    editorCommand: 'setParagraph',
    label: __('Normal text'),
  },
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
    contentType: 'heading',
    editorCommand: 'setHeading',
    commandParams: { level: 5 },
    label: __('Heading 5'),
  },
  {
    contentType: 'heading',
    editorCommand: 'setHeading',
    commandParams: { level: 6 },
    label: __('Heading 6'),
  },
];

export const ALERT_EVENT = 'alert';
export const KEYDOWN_EVENT = 'keydown';

export const PARSE_HTML_PRIORITY_LOWEST = 1;
export const PARSE_HTML_PRIORITY_DEFAULT = 50;
export const PARSE_HTML_PRIORITY_HIGH = 75;
export const PARSE_HTML_PRIORITY_HIGHEST = 100;

export const EXTENSION_PRIORITY_LOWER = 75;
/**
 * 100 is the default priority in Tiptap
 * https://tiptap.dev/guide/custom-extensions/#priority
 */
export const EXTENSION_PRIORITY_DEFAULT = 100;
export const EXTENSION_PRIORITY_HIGHEST = 200;

/**
 * See lib/gitlab/file_type_detection.rb
 */
export const SAFE_VIDEO_EXT = ['mp4', 'm4v', 'mov', 'webm', 'ogv'];
export const SAFE_AUDIO_EXT = ['mp3', 'oga', 'ogg', 'spx', 'wav'];

export const DIAGRAM_LANGUAGES = ['plantuml', 'mermaid'];

export const TIPTAP_AUTOFOCUS_OPTIONS = [true, false, 'start', 'end', 'all'];

/**
 * Command related constants
 */
export const COMMANDS = {
  ASSIGN: '/assign',
  ASSIGN_REVIEWER: '/assign_reviewer',
  CC: '/cc',
  LABEL: '/label',
  MILESTONE: '/milestone',
  REASSIGN: '/reassign',
  REASSIGN_REVIEWER: '/reassign_reviewer',
  RELABEL: '/relabel',
  UNASSIGN: '/unassign',
  UNASSIGN_REVIEWER: '/unassign_reviewer',
  UNLABEL: '/unlabel',
  ITERATION: '/iteration',
};
