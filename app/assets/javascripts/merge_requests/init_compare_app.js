import Vue from 'vue';
import { observable } from '~/lib/utils/observable';
import { findTargetBranch } from 'ee_else_ce/pages/projects/merge_requests/creations/new/branch_finder';

import CompareApp from '~/merge_requests/components/compare_app.vue';
import { __ } from '~/locale';

import { loadingIconForLegacyJS } from '~/loading_icon_for_legacy_js';

/**
 * Adds a loading spinner to the "Compare branches and continue" submit button
 * when the form is submitted. Since this is a Rails form submission, the page
 * navigation or reload handles removing the loading state.
 */
export function initCompareButtonLoading() {
  const form = document.querySelector('.merge-request-form');
  if (!form) return;

  const submitButton = form.querySelector('.js-compare-branches-button');
  if (!submitButton) return;

  form.addEventListener('submit', () => {
    if (submitButton.disabled) return;

    const loader = loadingIconForLegacyJS({
      inline: true,
      size: 'sm',
      classes: ['gl-mr-3'],
    });

    submitButton.setAttribute('disabled', 'disabled');
    submitButton.prepend(loader);
  });
}

export function initCompareApp() {
  initCompareButtonLoading();

  const targetCompareEl = document.getElementById('js-target-project-dropdown');
  const sourceCompareEl = document.getElementById('js-source-project-dropdown');
  const compareEl = document.querySelector('.js-merge-request-new-compare');
  const targetBranch = observable('mr_new_target_branch', { name: '' });
  const currentSourceBranch = JSON.parse(sourceCompareEl.dataset.currentBranch);
  const sourceBranchErrorDescriptionId = sourceCompareEl.dataset.branchErrorDescriptionId || null;
  const sourceBranch = observable('mr_new_source_branch', currentSourceBranch);

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
          ariaDescribedby: sourceBranchErrorDescriptionId,
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
          currentBranch: sourceBranch,
        },
        on: {
          'select-branch': this.selectedBranch,
        },
      });
    },
  });

  const currentTargetBranch = JSON.parse(targetCompareEl.dataset.currentBranch);
  const targetBranchErrorDescriptionId = targetCompareEl.dataset.branchErrorDescriptionId || null;
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
          ariaDescribedby: targetBranchErrorDescriptionId,
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
}
