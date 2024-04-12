import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import csrf from '~/lib/utils/csrf';
import AdminUsersApp from './components/app.vue';
import DeleteUserModal from './components/modals/delete_user_modal.vue';
import UserActions from './components/user_actions.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

const initApp = (el, component, userPropKey, props = {}) => {
  if (!el) {
    return false;
  }

  const { [userPropKey]: user, paths } = el.dataset;

  return new Vue({
    el,
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

export const initAdminUsersApp = (el = document.querySelector('#js-admin-users-app')) =>
  initApp(el, AdminUsersApp, 'users');

export const initAdminUserActions = (el = document.querySelector('#js-admin-user-actions')) =>
  initApp(el, UserActions, 'user', { showButtonLabels: true });

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
