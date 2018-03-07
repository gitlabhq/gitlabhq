import Compare from '~/compare';
import MergeRequest from '~/merge_request';
import initPipelines from '~/commit/pipelines/pipelines_bundle';

document.addEventListener('DOMContentLoaded', () => {
  const mrNewCompareNode = document.querySelector('.js-merge-request-new-compare');
  if (mrNewCompareNode) {
    new Compare({ // eslint-disable-line no-new
      targetProjectUrl: mrNewCompareNode.dataset.targetProjectUrl,
      sourceBranchUrl: mrNewCompareNode.dataset.sourceBranchUrl,
      targetBranchUrl: mrNewCompareNode.dataset.targetBranchUrl,
    });
  } else {
    const mrNewSubmitNode = document.querySelector('.js-merge-request-new-submit');
    new MergeRequest({ // eslint-disable-line no-new
      action: mrNewSubmitNode.dataset.mrSubmitAction,
    });
    initPipelines();
  }
});
