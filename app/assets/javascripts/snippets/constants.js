import { __, s__ } from '~/locale';
import {
  VISIBILITY_LEVEL_PRIVATE_STRING,
  VISIBILITY_LEVEL_INTERNAL_STRING,
  VISIBILITY_LEVEL_PUBLIC_STRING,
} from '~/visibility_level/constants';

export const SNIPPET_VISIBILITY = {
  [VISIBILITY_LEVEL_PRIVATE_STRING]: {
    label: __('Private'),
    icon: 'lock',
    description: __('The snippet is visible only to me.'),
    description_project: __('The snippet is visible only to project members.'),
  },
  [VISIBILITY_LEVEL_INTERNAL_STRING]: {
    label: __('Internal'),
    icon: 'shield',
    description: __('The snippet is visible to any logged in user except external users.'),
  },
  [VISIBILITY_LEVEL_PUBLIC_STRING]: {
    label: __('Public'),
    icon: 'earth',
    description: __('The snippet can be accessed without any authentication.'),
    description_project: __(
      'The snippet can be accessed without any authentication. To embed snippets, a project must be public.',
    ),
  },
};

export const SNIPPET_CREATE_MUTATION_ERROR = __("Can't create snippet: %{err}");
export const SNIPPET_UPDATE_MUTATION_ERROR = __("Can't update snippet: %{err}");
export const SNIPPET_BLOB_CONTENT_FETCH_ERROR = __("Can't fetch content for the blob: %{err}");

export const SNIPPET_BLOB_ACTION_CREATE = 'create';
export const SNIPPET_BLOB_ACTION_UPDATE = 'update';
export const SNIPPET_BLOB_ACTION_MOVE = 'move';
export const SNIPPET_BLOB_ACTION_DELETE = 'delete';

export const SNIPPET_MAX_BLOBS = 10;

export const SNIPPET_LEVELS_RESTRICTED = __(
  'Other visibility settings have been disabled by the administrator.',
);
export const SNIPPET_LEVELS_DISABLED = __(
  'Visibility settings have been disabled by the administrator.',
);

export const SNIPPET_LIMITATIONS = s__('Snippets|Snippets are limited to %{total} files.');
