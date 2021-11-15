import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import CrmContactsRoot from './components/contacts_root.vue';

Vue.use(VueApollo);

export default () => {
  const el = document.getElementById('js-crm-contacts-app');

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    apolloProvider,
    provide: { groupFullPath: el.dataset.groupFullPath },
    render(createElement) {
      return createElement(CrmContactsRoot);
    },
  });
};
