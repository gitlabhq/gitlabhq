import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Translate from '~/vue_shared/translate';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import csrf from '~/lib/utils/csrf';
import AdminUsersApp from './components/app.vue';
import AdminUsersFilterApp from './components/admin_users_filter_app.vue';
import DeleteUserModal from './components/modals/delete_user_modal.vue';
import UserActions from './components/user_actions.vue';

Vue.use(Translate);
Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

// eslint-disable-next-line max-params
const initApp = (el, component, userPropKey, props = {}, provide = {}) => {
  if (!el) {
    return false;
  }

  const { [userPropKey]: user, paths } = el.dataset;

  return new Vue({
    el,
    provide: {
      ...provide,
    },
    apolloProvider,
    render: (createElement) =>
      createElement(component, {
        props: {
          [userPropKey]: convertObjectPropsToCamelCase(JSON.parse(user), { deep: true }),
          paths: convertObjectPropsToCamelCase(JSON.parse(paths)),
          ...props,
        },
      }),
  });
};

export const initAdminUsersFilterApp = () => {
  return new Vue({
    el: document.querySelector('#js-admin-users-filter-app'),
    render: (createElement) => createElement(AdminUsersFilterApp),
  });
};

export const initAdminUserActions = (el = document.querySelector('#js-admin-user-actions')) =>
  initApp(el, UserActions, 'user', { showButtonLabels: true });

export const initAdminUsersApp = (el = document.querySelector('#js-admin-users-app')) =>
  initApp(
    el,
    AdminUsersApp,
    'users',
    {},
    {
      isAtSeatsLimit: parseBoolean(el?.dataset?.isAtSeatsLimit),
    },
  );

export const initDeleteUserModals = () => {
  return new Vue({
    functional: true,
    render: (createElement) =>
      createElement(DeleteUserModal, {
        props: {
          csrfToken: csrf.token,
        },
      }),
  }).$mount();
};
