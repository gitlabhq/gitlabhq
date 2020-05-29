import $ from 'jquery';
import 'jquery.waitforimages';

import Vue from 'vue';
import initBlob from '~/blob_edit/blob_bundle';
import commitPipelineStatus from '~/projects/tree/components/commit_pipeline_status_component.vue';
import GpgBadges from '~/gpg_badges';
import TreeView from '../../../../tree';
import ShortcutsNavigation from '../../../../behaviors/shortcuts/shortcuts_navigation';
import BlobViewer from '../../../../blob/viewer';
import NewCommitForm from '../../../../new_commit_form';
import { ajaxGet } from '../../../../lib/utils/common_utils';

document.addEventListener('DOMContentLoaded', () => {
  new ShortcutsNavigation(); // eslint-disable-line no-new
  new TreeView(); // eslint-disable-line no-new
  new BlobViewer(); // eslint-disable-line no-new
  new NewCommitForm($('.js-create-dir-form')); // eslint-disable-line no-new
  $('#tree-slider').waitForImages(() =>
    ajaxGet(document.querySelector('.js-tree-content').dataset.logsPath),
  );

  initBlob();
  const commitPipelineStatusEl = document.querySelector('.js-commit-pipeline-status');
  const statusLink = document.querySelector('.commit-actions .ci-status-link');
  if (statusLink != null) {
    statusLink.remove();
    // eslint-disable-next-line no-new
    new Vue({
      el: commitPipelineStatusEl,
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
  }

  GpgBadges.fetch();

  if (document.getElementById('js-tree-list')) {
    import('ee_else_ce/repository')
      .then(m => m.default())
      .catch(e => {
        throw e;
      });
  }
});
