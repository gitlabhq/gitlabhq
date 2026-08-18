import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import RefSelector from '~/vue_shared/components/ref/components/ref_selector.vue';

export default function initNewTagRefSelector() {
  const el = document.querySelector('.js-new-tag-ref-selector');

  if (el) {
    const { projectId, defaultBranchName, hiddenInputName } = el.dataset;

    initVueApp({
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
}
