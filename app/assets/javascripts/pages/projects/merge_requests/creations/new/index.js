import $ from 'jquery';
import Vue from 'vue';
import initPipelines from '~/commit/pipelines/pipelines_bundle';
import MergeRequest from '~/merge_request';
import TargetProjectDropdown from '~/merge_requests/components/target_project_dropdown.vue';
import initCompare from './compare';

const mrNewCompareNode = document.querySelector('.js-merge-request-new-compare');
if (mrNewCompareNode) {
  initCompare(mrNewCompareNode);

  const el = document.getElementById('js-target-project-dropdown');
  const { targetProjectsPath, currentProject } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'TargetProjectDropdown',
    provide: {
      targetProjectsPath,
      currentProject: JSON.parse(currentProject),
    },
    render(h) {
      return h(TargetProjectDropdown, {
        on: {
          'project-selected': function projectSelectedFunction(refsUrl) {
            const $targetBranchDropdown = $('.js-target-branch');
            $targetBranchDropdown.data('refsUrl', refsUrl);
            $targetBranchDropdown.data('deprecatedJQueryDropdown').clearMenu();
          },
        },
      });
    },
  });
} else {
  const mrNewSubmitNode = document.querySelector('.js-merge-request-new-submit');
  // eslint-disable-next-line no-new
  new MergeRequest({
    action: mrNewSubmitNode.dataset.mrSubmitAction,
  });
  initPipelines();
}
