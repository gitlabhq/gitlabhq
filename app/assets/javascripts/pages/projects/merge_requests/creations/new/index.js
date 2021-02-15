import initPipelines from '~/commit/pipelines/pipelines_bundle';
import MergeRequest from '~/merge_request';
import initCompare from './compare';

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
