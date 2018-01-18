import Vue from 'vue';
import TreeView from '../../../../tree';
import ShortcutsNavigation from '../../../../shortcuts_navigation';
import BlobViewer from '../../../../blob/viewer';
import NewCommitForm from '../../../../new_commit_form';
import { ajaxGet } from '../../../../lib/utils/common_utils';
import commitPipelineStatus from '../components/commit_pipeline_status_component.vue';

export default () => {
  new ShortcutsNavigation(); // eslint-disable-line no-new
  new TreeView(); // eslint-disable-line no-new
  new BlobViewer(); // eslint-disable-line no-new
  new NewCommitForm($('.js-create-dir-form')); // eslint-disable-line no-new
  $('#tree-slider').waitForImages(() =>
    ajaxGet(document.querySelector('.js-tree-content').dataset.logsPath));

  const commitPipelineStatusEl = document.getElementById('commit-pipeline-status');
  // eslint-disable-next-line no-new
  new Vue({
    el: '#commit-pipeline-status',
    components: {
      commitPipelineStatus,
    },
    render(createElement) {
      return createElement('commit-pipeline-status', {
        props: {
          endpoint: commitPipelineStatusEl.dataset.endpoint,
        },
      });
    },
  });
};

