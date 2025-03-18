import toast from '~/vue_shared/plugins/global_toast';
import { sprintf, __ } from '~/locale';

export const renderDeleteSuccessToast = (group) => {
  toast(
    sprintf(__("Group '%{group_name}' is being deleted."), {
      group_name: group.fullName,
    }),
  );
};

export const deleteParams = () => {
  // Overridden in EE
  return {};
};
