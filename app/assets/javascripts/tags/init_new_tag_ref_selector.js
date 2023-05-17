import Vue from 'vue';
import RefSelector from '~/ref/components/ref_selector.vue';

export default function initNewTagRefSelector() {
  const el = document.querySelector('.js-new-tag-ref-selector');

  if (el) {
    const { projectId, defaultBranchName, hiddenInputName } = el.dataset;
    // eslint-disable-next-line no-new
    new Vue({
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
}
