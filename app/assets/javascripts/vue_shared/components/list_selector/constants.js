import { __ } from '~/locale';

// Note, we can extend this config in future to make the component work in other contexts
// https://gitlab.com/gitlab-org/gitlab/-/issues/428865
export const CONFIG = {
  users: { title: __('Users'), icon: 'user', filterKey: 'username' },
};
