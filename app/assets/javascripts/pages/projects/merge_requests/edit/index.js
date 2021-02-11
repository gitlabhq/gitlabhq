import initMergeRequest from '~/pages/projects/merge_requests/init_merge_request';
import initCheckFormState from './check_form_state';

document.addEventListener('DOMContentLoaded', () => {
  initMergeRequest();
  initCheckFormState();
});
