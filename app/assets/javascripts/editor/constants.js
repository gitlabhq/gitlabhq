import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { s__, __ } from '~/locale';

export const URI_PREFIX = 'gitlab';
export const CONTENT_UPDATE_DEBOUNCE = DEFAULT_DEBOUNCE_AND_THROTTLE_MS;

export const EDITOR_READY_EVENT = 'editor-ready';

export const EDITOR_TYPE_CODE = 'vs.editor.ICodeEditor';
export const EDITOR_TYPE_DIFF = 'vs.editor.IDiffEditor';

export const EDITOR_CODE_INSTANCE_FN = 'createInstance';
export const EDITOR_DIFF_INSTANCE_FN = 'createDiffInstance';

export const EDITOR_TOOLBAR_LEFT_GROUP = 'left';
export const EDITOR_TOOLBAR_RIGHT_GROUP = 'right';

export const SOURCE_EDITOR_INSTANCE_ERROR_NO_EL = s__(
  'SourceEditor|"el" parameter is required for createInstance()',
);
export const ERROR_INSTANCE_REQUIRED_FOR_EXTENSION = s__(
  'SourceEditor|Source Editor instance is required to set up an extension.',
);
export const EDITOR_EXTENSION_DEFINITION_ERROR = s__(
  'SourceEditor|Extension definition should be either a class or a function',
);
export const EDITOR_EXTENSION_NO_DEFINITION_ERROR = s__(
  'SourceEditor|`definition` property is expected on the extension.',
);
export const EDITOR_EXTENSION_DEFINITION_TYPE_ERROR = s__(
  'SourceEditor|Extension definition should be either class, function, or an Array of definitions.',
);
export const EDITOR_EXTENSION_NOT_SPECIFIED_FOR_UNUSE_ERROR = s__(
  'SourceEditor|No extension for unuse has been specified.',
);
export const EDITOR_EXTENSION_NOT_REGISTERED_ERROR = s__('SourceEditor|%{name} is not registered.');
export const EDITOR_EXTENSION_NAMING_CONFLICT_ERROR = s__(
  'SourceEditor|Name conflict for "%{prop}()" method.',
);
export const EDITOR_EXTENSION_STORE_IS_MISSING_ERROR = s__(
  'SourceEditor|Extensions Store is required to check for an extension.',
);

//
// EXTENSIONS' CONSTANTS
//

// Source Editor Base Extension
export const EXTENSION_BASE_LINE_LINK_ANCHOR_CLASS = 'link-anchor';
export const EXTENSION_BASE_LINE_NUMBERS_CLASS = 'line-numbers';

// For CI config schemas the filename must match
// '*.gitlab-ci.yml' regardless of project configuration.
// https://gitlab.com/gitlab-org/gitlab/-/issues/293641
export const EXTENSION_CI_SCHEMA_FILE_NAME_MATCH = '.gitlab-ci.yml';

export const EXTENSION_MARKDOWN_PREVIEW_PANEL_CLASS = 'md';
export const EXTENSION_MARKDOWN_PREVIEW_PANEL_PARENT_CLASS = 'source-editor-preview';
export const EXTENSION_MARKDOWN_PREVIEW_ACTION_ID = 'markdown-preview';
export const EXTENSION_MARKDOWN_PREVIEW_HIDE_ACTION_ID = 'markdown-preview-hide';
export const EXTENSION_MARKDOWN_PREVIEW_PANEL_WIDTH = 0.5; // 50% of the width
export const EXTENSION_MARKDOWN_PREVIEW_UPDATE_DELAY = 250; // ms
export const EXTENSION_MARKDOWN_PREVIEW_LABEL = __('Preview Markdown');
export const EXTENSION_MARKDOWN_HIDE_PREVIEW_LABEL = __('Hide Live Preview');
