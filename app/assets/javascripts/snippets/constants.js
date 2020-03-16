import { __ } from '~/locale';

export const SNIPPET_VISIBILITY_PRIVATE = 'private';
export const SNIPPET_VISIBILITY_INTERNAL = 'internal';
export const SNIPPET_VISIBILITY_PUBLIC = 'public';

export const SNIPPET_VISIBILITY = {
  private: {
    label: __('Private'),
    description: __('The snippet is visible only to me.'),
    description_project: __('The snippet is visible only to project members.'),
  },
  internal: {
    label: __('Internal'),
    description: __('The snippet is visible to any logged in user.'),
  },
  public: {
    label: __('Public'),
    description: __('The snippet can be accessed without any authentication.'),
  },
};
