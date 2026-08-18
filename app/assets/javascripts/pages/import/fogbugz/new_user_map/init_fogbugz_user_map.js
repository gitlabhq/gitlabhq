import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import UserSelect from './components/user_select.vue';

Vue.use(VueApollo);

export function initFogbugzUserMap() {
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return Array.from(document.querySelectorAll('.js-gitlab-user')).map((node) =>
    initVueApp({
      el: node,
      name: 'UserSelectRoot',
      apolloProvider,
      component: UserSelect,
      props: { name: node.dataset.name },
    }),
  );
}
