import { disableButtonIfEmptyField } from '~/lib/utils/common_utils';

// This is only used when `invite_members_group_modal` feature flag is disabled.
// This file can be removed when `invite_members_group_modal` feature flag is removed
export default () => {
  disableButtonIfEmptyField('#user_ids', 'input[name=commit]', 'change');
};
