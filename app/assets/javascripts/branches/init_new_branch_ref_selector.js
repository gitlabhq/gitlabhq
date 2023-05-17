import Vue from 'vue';
import RefSelector from '~/ref/components/ref_selector.vue';

export default function initNewBranchRefSelector() {
  const el = document.querySelector('.js-new-branch-ref-selector');

  if (!el) {
    return false;
  }

  const { projectId, defaultBranchName, hiddenInputName } = el.dataset;

  return new Vue({
    el,
    render(createComponent) {
      return createComponent(RefSelector, {
        props: {
          value: defaultBranchName,
          name: hiddenInputName,
          queryParams: { sort: 'updated_desc' },
          projectId,
        },
      });
    },
  });
}
