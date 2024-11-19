import Vue from 'vue';

import { initMarkdownEditor } from 'ee_else_ce/pages/projects/merge_requests/init_markdown_editor';
import { findTargetBranch } from 'ee_else_ce/pages/projects/merge_requests/creations/new/branch_finder';

import initPipelines from '~/commit/pipelines/pipelines_bundle';
import MergeRequest from '~/merge_request';
import CompareApp from '~/merge_requests/components/compare_app.vue';
import { __ } from '~/locale';

const mrNewCompareNode = document.querySelector('.js-merge-request-new-compare');
if (mrNewCompareNode) {
  const targetCompareEl = document.getElementById('js-target-project-dropdown');
  const sourceCompareEl = document.getElementById('js-source-project-dropdown');
  const compareEl = document.querySelector('.js-merge-request-new-compare');
  const targetBranch = Vue.observable({ name: '' });
  const currentSourceBranch = JSON.parse(sourceCompareEl.dataset.currentBranch);
  const sourceBranch = Vue.observable(currentSourceBranch);

  // eslint-disable-next-line no-new
  new Vue({
    el: sourceCompareEl,
    name: 'SourceCompareApp',
    provide: {
      currentProject: JSON.parse(sourceCompareEl.dataset.currentProject),
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
      compareSide: 'source',
    },
    methods: {
      async selectedBranch(branchName) {
        const targetBranchName = await findTargetBranch(branchName);

        if (targetBranchName) {
          targetBranch.name = targetBranchName;
        }

        sourceBranch.value = branchName;
        sourceBranch.text = branchName;
      },
    },
    render(h) {
      return h(CompareApp, {
        props: {
          currentBranch: currentSourceBranch,
        },
        on: {
          'select-branch': this.selectedBranch,
        },
      });
    },
  });

  const currentTargetBranch = JSON.parse(targetCompareEl.dataset.currentBranch);
  // eslint-disable-next-line no-new
  new Vue({
    el: targetCompareEl,
    name: 'TargetCompareApp',
    provide: {
      currentProject: JSON.parse(targetCompareEl.dataset.currentProject),
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
    computed: {
      currentBranch() {
        if (targetBranch.name) {
          return { text: targetBranch.name, value: targetBranch.name };
        }

        return currentTargetBranch;
      },
      isDisabled() {
        return !sourceBranch.value;
      },
    },
    render(h) {
      return h(CompareApp, {
        props: { currentBranch: this.currentBranch, disabled: this.isDisabled },
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
  initMarkdownEditor();
}
