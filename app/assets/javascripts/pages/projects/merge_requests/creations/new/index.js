import MergeRequest from '~/merge_request';
import initPipelines from '~/commit/pipelines/pipelines_bundle';
import initCompare from './compare';

document.addEventListener('DOMContentLoaded', () => {
  const mrNewCompareNode = document.querySelector('.js-merge-request-new-compare');
  if (mrNewCompareNode) {
    initCompare(mrNewCompareNode);
  } else {
    const mrNewSubmitNode = document.querySelector('.js-merge-request-new-submit');
    // eslint-disable-next-line no-new
    new MergeRequest({
      action: mrNewSubmitNode.dataset.mrSubmitAction,
    });
    initPipelines();
  }
});
