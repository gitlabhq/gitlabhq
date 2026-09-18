import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { __ } from '~/locale';
import { REF_TYPE_BRANCHES } from '~/vue_shared/components/ref/constants';
import RefSelector from '~/vue_shared/components/ref/components/ref_selector.vue';

export default function initTargetBranchRefSelector() {
  const el = document.querySelector('.js-target-branch-ref-selector');

  if (!el) {
    return null;
  }

  const { projectId, targetBranch } = el.dataset;
  const formField = document.querySelector('#merge_request_target_branch');

  return initVueApp({
    el,
    name: 'TargetBranchRefSelectorRoot',
    component: RefSelector,
    props: {
      projectId,
      value: targetBranch,
      enabledRefTypes: [REF_TYPE_BRANCHES],
      queryParams: { sort: 'updated_desc' },
      toggleButtonClass: 'js-target-branch gl-font-monospace',
      translations: {
        dropdownHeader: __('Select branch'),
        searchPlaceholder: __('Search branches'),
      },
    },
    events: {
      // Set the attribute, not the property: the EE approvals app watches it
      // with a MutationObserver to refetch the approval rules.
      input(selectedRef) {
        formField?.setAttribute('value', selectedRef);
      },
    },
  });
}
