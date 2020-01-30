import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import DismissibleAlert from '~/vue_shared/components/dismissible_alert.vue';

const mountVueAlert = el => {
  const props = {
    html: el.innerHTML,
  };
  const attrs = {
    ...el.dataset,
    dismissible: parseBoolean(el.dataset.dismissible),
  };

  return new Vue({
    el,
    render(h) {
      return h(DismissibleAlert, { props, attrs });
    },
  });
};

export default () => [...document.querySelectorAll('.js-vue-alert')].map(mountVueAlert);
