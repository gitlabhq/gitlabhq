import GpgBadges from '~/gpg_badges';

import { initCompareApp } from '~/merge_requests/init_compare_app';

import MergeRequest from '~/merge_request';
import initPipelines from '~/commit/pipelines/pipelines_bundle';
import { createRapidDiffsApp } from '~/rapid_diffs';
import { initMarkdownEditor } from 'ee_else_ce/pages/projects/merge_requests/init_markdown_editor';

GpgBadges.fetch();

const mrNewCompareNode = document.querySelector('.js-merge-request-new-compare');
if (mrNewCompareNode) {
  initCompareApp();
} else {
  const mrNewSubmitNode = document.querySelector('.js-merge-request-new-submit');
  // eslint-disable-next-line no-new
  new MergeRequest({
    action: mrNewSubmitNode.dataset.mrSubmitAction,
    createRapidDiffsApp,
  });
  initPipelines();
  initMarkdownEditor();
}
