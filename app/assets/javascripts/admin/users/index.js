import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import AdminUsersApp from './components/app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient({}, { assumeImmutableResults: true }),
});

export const initAdminUsersApp = (el = document.querySelector('#js-admin-users-app')) => {
  if (!el) {
    return false;
  }

  const { users, paths } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    render: (createElement) =>
      createElement(AdminUsersApp, {
        props: {
          users: convertObjectPropsToCamelCase(JSON.parse(users), { deep: true }),
          paths: convertObjectPropsToCamelCase(JSON.parse(paths)),
        },
      }),
  });
};
