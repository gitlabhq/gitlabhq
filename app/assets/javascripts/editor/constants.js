import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { s__ } from '~/locale';

export const SOURCE_EDITOR_INSTANCE_ERROR_NO_EL = s__(
  'SourceEditor|"el" parameter is required for createInstance()',
);

export const URI_PREFIX = 'gitlab';
export const CONTENT_UPDATE_DEBOUNCE = DEFAULT_DEBOUNCE_AND_THROTTLE_MS;

export const ERROR_INSTANCE_REQUIRED_FOR_EXTENSION = s__(
  'SourceEditor|Source Editor instance is required to set up an extension.',
);

export const EDITOR_READY_EVENT = 'editor-ready';

export const EDITOR_TYPE_CODE = 'vs.editor.ICodeEditor';
export const EDITOR_TYPE_DIFF = 'vs.editor.IDiffEditor';

export const EDITOR_CODE_INSTANCE_FN = 'createInstance';
export const EDITOR_DIFF_INSTANCE_FN = 'createDiffInstance';

export const EDITOR_EXTENSION_DEFINITION_ERROR = s__(
  'SourceEditor|Extension definition should be either a class or a function',
);

//
// EXTENSIONS' CONSTANTS
//

// For CI config schemas the filename must match
// '*.gitlab-ci.yml' regardless of project configuration.
// https://gitlab.com/gitlab-org/gitlab/-/issues/293641
export const EXTENSION_CI_SCHEMA_FILE_NAME_MATCH = '.gitlab-ci.yml';

export const EXTENSION_MARKDOWN_PREVIEW_PANEL_CLASS = 'md';
export const EXTENSION_MARKDOWN_PREVIEW_PANEL_PARENT_CLASS = 'source-editor-preview';
export const EXTENSION_MARKDOWN_PREVIEW_ACTION_ID = 'markdown-preview';
export const EXTENSION_MARKDOWN_PREVIEW_PANEL_WIDTH = 0.5; // 50% of the width
export const EXTENSION_MARKDOWN_PREVIEW_UPDATE_DELAY = 250; // ms
