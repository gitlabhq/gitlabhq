import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import CommitPipelineStatus from '~/projects/tree/components/commit_pipeline_status.vue';

export default function initCommitPipelineStatus() {
  const commitPipelineStatusEl = document.querySelector('.js-commit-pipeline-status');
  if (!commitPipelineStatusEl) return null;

  return initVueApp({
    el: commitPipelineStatusEl,
    name: 'BlobCommitPipelineStatusRoot',
    component: CommitPipelineStatus,
    props: {
      endpoint: commitPipelineStatusEl.dataset.endpoint,
    },
  });
}
