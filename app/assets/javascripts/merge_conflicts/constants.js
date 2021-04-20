import { s__ } from '~/locale';

export const CONFLICT_TYPES = {
  TEXT: 'text',
  TEXT_EDITOR: 'text-editor',
};

export const VIEW_TYPES = {
  INLINE: 'inline',
  PARALLEL: 'parallel',
};

export const EDIT_RESOLVE_MODE = 'edit';
export const INTERACTIVE_RESOLVE_MODE = 'interactive';
export const DEFAULT_RESOLVE_MODE = INTERACTIVE_RESOLVE_MODE;
export const SYNTAX_HIGHLIGHT_CLASS = 'js-syntax-highlight';

export const HEAD_HEADER_TEXT = s__('MergeConflict|HEAD//our changes');
export const ORIGIN_HEADER_TEXT = s__('MergeConflict|origin//their changes');
export const HEAD_BUTTON_TITLE = s__('MergeConflict|Use ours');
export const ORIGIN_BUTTON_TITLE = s__('MergeConflict|Use theirs');
