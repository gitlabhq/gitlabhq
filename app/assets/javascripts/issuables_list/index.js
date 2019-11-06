import Vue from 'vue';
import IssuablesListApp from './components/issuables_list_app.vue';

export default function initIssuablesList() {
  if (!gon.features || !gon.features.vueIssuablesList) {
    return;
  }

  document.querySelectorAll('.js-issuables-list').forEach(el => {
    const { canBulkEdit, ...data } = el.dataset;

    const props = {
      ...data,
      canBulkEdit: Boolean(canBulkEdit),
    };

    return new Vue({
      el,
      render(createElement) {
        return createElement(IssuablesListApp, { props });
      },
    });
  });
}
