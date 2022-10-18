import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import UserSelect from './components/user_select.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

Array.from(document.querySelectorAll('.js-gitlab-user')).forEach(
  (node) =>
    new Vue({
      el: node,
      apolloProvider,
      render: (h) => h(UserSelect, { props: { name: node.dataset.name } }),
    }),
);
