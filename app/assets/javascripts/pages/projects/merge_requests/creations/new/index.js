import Vue from 'vue';
import initPipelines from '~/commit/pipelines/pipelines_bundle';
import MergeRequest from '~/merge_request';
import CompareApp from '~/merge_requests/components/compare_app.vue';
import { __ } from '~/locale';
import { mountMarkdownEditor } from '~/vue_shared/components/markdown/mount_markdown_editor';
import IssuableTemplateSelectors from '~/issuable/issuable_template_selectors';

const mrNewCompareNode = document.querySelector('.js-merge-request-new-compare');
if (mrNewCompareNode) {
  const targetCompareEl = document.getElementById('js-target-project-dropdown');
  const sourceCompareEl = document.getElementById('js-source-project-dropdown');
  const compareEl = document.querySelector('.js-merge-request-new-compare');

  // eslint-disable-next-line no-new
  new Vue({
    el: sourceCompareEl,
    name: 'SourceCompareApp',
    provide: {
      currentProject: JSON.parse(sourceCompareEl.dataset.currentProject),
      currentBranch: JSON.parse(sourceCompareEl.dataset.currentBranch),
      branchCommitPath: compareEl.dataset.sourceBranchUrl,
      inputs: {
        project: {
          id: 'merge_request_source_project_id',
          name: 'merge_request[source_project_id]',
        },
        branch: {
          id: 'merge_request_source_branch',
          name: 'merge_request[source_branch]',
        },
      },
      i18n: {
        projectHeaderText: __('Select source project'),
        branchHeaderText: __('Select source branch'),
      },
      toggleClass: {
        project: 'js-source-project',
        branch: 'js-source-branch gl-font-monospace',
      },
      branchQaSelector: 'source_branch_dropdown',
    },
    render(h) {
      return h(CompareApp);
    },
  });

  // eslint-disable-next-line no-new
  new Vue({
    el: targetCompareEl,
    name: 'TargetCompareApp',
    provide: {
      currentProject: JSON.parse(targetCompareEl.dataset.currentProject),
      currentBranch: JSON.parse(targetCompareEl.dataset.currentBranch),
      projectsPath: targetCompareEl.dataset.targetProjectsPath,
      branchCommitPath: compareEl.dataset.targetBranchUrl,
      inputs: {
        project: {
          id: 'merge_request_target_project_id',
          name: 'merge_request[target_project_id]',
        },
        branch: {
          id: 'merge_request_target_branch',
          name: 'merge_request[target_branch]',
        },
      },
      i18n: {
        projectHeaderText: __('Select target project'),
        branchHeaderText: __('Select target branch'),
      },
      toggleClass: {
        project: 'js-target-project',
        branch: 'js-target-branch gl-font-monospace',
      },
    },
    render(h) {
      return h(CompareApp);
    },
  });
} else {
  const mrNewSubmitNode = document.querySelector('.js-merge-request-new-submit');
  // eslint-disable-next-line no-new
  new MergeRequest({
    action: mrNewSubmitNode.dataset.mrSubmitAction,
  });
  initPipelines();
  // eslint-disable-next-line no-new
  new IssuableTemplateSelectors({ warnTemplateOverride: true, editor: mountMarkdownEditor() });
}
