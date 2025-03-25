import { initMarkdownEditor } from 'ee_else_ce/pages/projects/merge_requests/init_markdown_editor';
import initPipelines from '~/commit/pipelines/pipelines_bundle';
import MergeRequest from '~/merge_request';

const mrNewSubmitNode = document.querySelector('.js-merge-request-new-submit');

// eslint-disable-next-line no-new
new MergeRequest({
  action: mrNewSubmitNode.dataset.mrSubmitAction,
});
initPipelines();
initMarkdownEditor();
