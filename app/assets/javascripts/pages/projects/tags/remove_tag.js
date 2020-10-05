import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import initConfirmModal from '~/confirm_modal';

export const initRemoveTag = ({ onDelete = () => {} }) => {
  return initConfirmModal({
    handleSubmit: (path = '') =>
      axios
        .delete(path)
        .then(() => onDelete(path))
        .catch(({ response: { data } }) => {
          const { message } = data;
          createFlash({ message });
        }),
  });
};
