import Vue from 'vue';
import CommitPipelineStatus from '~/projects/tree/components/commit_pipeline_status.vue';

export default function initCommitPipelineStatus() {
  const commitPipelineStatusEl = document.querySelector('.js-commit-pipeline-status');
  if (!commitPipelineStatusEl) return null;

  return new Vue({
    el: commitPipelineStatusEl,
    name: 'BlobCommitPipelineStatusRoot',
    components: {
      CommitPipelineStatus,
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
