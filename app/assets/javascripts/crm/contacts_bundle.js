import Vue from 'vue';
import CrmContactsRoot from './components/contacts_root.vue';

export default () => {
  const el = document.getElementById('js-crm-contacts-app');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    render(createElement) {
      return createElement(CrmContactsRoot);
    },
  });
};
