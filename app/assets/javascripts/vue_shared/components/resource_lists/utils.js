import toast from '~/vue_shared/plugins/global_toast';
import { sprintf, __ } from '~/locale';

export const renderDeleteSuccessToast = (item, type) => {
  toast(
    sprintf(__("%{type} '%{name}' is being deleted."), {
      type,
      name: item.name,
    }),
  );
};

export const deleteParams = () => {
  // Overridden in EE
  return {};
};
