import AjaxLoadingSpinner from '~/ajax_loading_spinner';
import DeleteModal from '~/branches/branches_delete_modal';

export default () => {
  AjaxLoadingSpinner.init();
  new DeleteModal(); // eslint-disable-line no-new
};
