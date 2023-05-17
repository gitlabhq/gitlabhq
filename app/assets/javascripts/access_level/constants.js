import { __ } from '~/locale';

// Matches `lib/gitlab/access.rb`
export const ACCESS_LEVEL_NO_ACCESS_INTEGER = 0;
export const ACCESS_LEVEL_MINIMAL_ACCESS_INTEGER = 5;
export const ACCESS_LEVEL_GUEST_INTEGER = 10;
export const ACCESS_LEVEL_REPORTER_INTEGER = 20;
export const ACCESS_LEVEL_DEVELOPER_INTEGER = 30;
export const ACCESS_LEVEL_MAINTAINER_INTEGER = 40;
export const ACCESS_LEVEL_OWNER_INTEGER = 50;

export const ACCESS_LEVEL_LABELS = {
  [ACCESS_LEVEL_NO_ACCESS_INTEGER]: __('No access'),
  [ACCESS_LEVEL_MINIMAL_ACCESS_INTEGER]: __('Minimal Access'),
  [ACCESS_LEVEL_GUEST_INTEGER]: __('Guest'),
  [ACCESS_LEVEL_REPORTER_INTEGER]: __('Reporter'),
  [ACCESS_LEVEL_DEVELOPER_INTEGER]: __('Developer'),
  [ACCESS_LEVEL_MAINTAINER_INTEGER]: __('Maintainer'),
  [ACCESS_LEVEL_OWNER_INTEGER]: __('Owner'),
};
