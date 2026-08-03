import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import RefSelector from '~/ref/components/ref_selector.vue';

export default function initNewBranchRefSelector() {
  const el = document.querySelector('.js-new-branch-ref-selector');

  if (!el) {
    return false;
  }

  const { projectId, defaultBranchName, hiddenInputName } = el.dataset;

  return initVueApp({
    el,
    name: 'RefSelectorRoot',
    component: RefSelector,
    props: {
      value: defaultBranchName,
      name: hiddenInputName,
      queryParams: { sort: 'updated_desc' },
      projectId,
      useSymbolicRefNames: true,
    },
  });
}
