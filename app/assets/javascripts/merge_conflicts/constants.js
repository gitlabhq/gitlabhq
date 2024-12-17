import { unescape } from 'lodash';
import { s__, sprintf } from '~/locale';
import { sanitize } from '~/lib/dompurify';

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

export const createHeadHeaderText = ({ commit, message }) =>
  sprintf(
    unescape(
      sanitize(
        s__('MergeConflict|&gt;&gt;&gt;&gt;&gt;&gt;&gt; %{commit}: %{message} (our changes)'),
        {
          ALLOWED_TAGS: [],
        },
      ),
    ),
    { commit, message },
  );

export const createOriginHeaderText = ({ target }) =>
  sprintf(
    unescape(
      sanitize(s__('MergeConflict|&lt;&lt;&lt;&lt;&lt;&lt;&lt; HEAD: %{target} (their changes)'), {
        ALLOWED_TAGS: [],
      }),
    ),
    { target },
  );

export const HEAD_BUTTON_TITLE = s__('MergeConflict|Use ours');
export const ORIGIN_BUTTON_TITLE = s__('MergeConflict|Use theirs');
