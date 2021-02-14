import initPipelines from '~/commit/pipelines/pipelines_bundle';
import initCommitActions from '~/projects/commit';
import { initCommitBoxInfo } from '~/projects/commit_box/info';

initCommitBoxInfo();
initPipelines();
initCommitActions();
