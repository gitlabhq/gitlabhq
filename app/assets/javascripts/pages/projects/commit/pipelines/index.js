import { initCommitBoxInfo } from '~/projects/commit_box/info';
import initPipelines from '~/commit/pipelines/pipelines_bundle';

document.addEventListener('DOMContentLoaded', () => {
  initCommitBoxInfo();

  initPipelines();
});
