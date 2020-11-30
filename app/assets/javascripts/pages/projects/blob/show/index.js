import Vue from 'vue';
import commitPipelineStatus from '~/projects/tree/components/commit_pipeline_status_component.vue';
import BlobViewer from '~/blob/viewer/index';
import initBlob from '~/pages/projects/init_blob';
import GpgBadges from '~/gpg_badges';
import initWebIdeLink from '~/pages/projects/shared/web_ide_link';
import '~/sourcegraph/load';
import PipelineTourSuccessModal from '~/blob/pipeline_tour_success_modal.vue';

document.addEventListener('DOMContentLoaded', () => {
  new BlobViewer(); // eslint-disable-line no-new
  initBlob();

  const CommitPipelineStatusEl = document.querySelector('.js-commit-pipeline-status');
  const statusLink = document.querySelector('.commit-actions .ci-status-link');
  if (statusLink) {
    statusLink.remove();
    // eslint-disable-next-line no-new
    new Vue({
      el: CommitPipelineStatusEl,
      components: {
        commitPipelineStatus,
      },
      render(createElement) {
        return createElement('commit-pipeline-status', {
          props: {
            endpoint: CommitPipelineStatusEl.dataset.endpoint,
          },
        });
      },
    });
  }

  initWebIdeLink({ el: document.getElementById('js-blob-web-ide-link') });

  GpgBadges.fetch();

  const codeNavEl = document.getElementById('js-code-navigation');

  if (codeNavEl) {
    const { codeNavigationPath, blobPath, definitionPathPrefix } = codeNavEl.dataset;

    // eslint-disable-next-line promise/catch-or-return
    import('~/code_navigation').then(m =>
      m.default({
        blobs: [{ path: blobPath, codeNavigationPath }],
        definitionPathPrefix,
      }),
    );
  }

  const successPipelineEl = document.querySelector('.js-success-pipeline-modal');

  if (successPipelineEl) {
    // eslint-disable-next-line no-new
    new Vue({
      el: successPipelineEl,
      render(createElement) {
        return createElement(PipelineTourSuccessModal, {
          props: {
            ...successPipelineEl.dataset,
          },
        });
      },
    });
  }
});
