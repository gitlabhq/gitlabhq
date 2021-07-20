import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import csrf from '~/lib/utils/csrf';
import AdminUsersApp from './components/app.vue';
import ModalManager from './components/modals/user_modal_manager.vue';
import UserActions from './components/user_actions.vue';
import {
  CONFIRM_DELETE_BUTTON_SELECTOR,
  MODAL_TEXTS_CONTAINER_SELECTOR,
  MODAL_MANAGER_SELECTOR,
} from './constants';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient({}, { assumeImmutableResults: true }),
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
  const modalsMountElement = document.querySelector(MODAL_TEXTS_CONTAINER_SELECTOR);

  if (!modalsMountElement) {
    return;
  }

  const modalConfiguration = Array.from(modalsMountElement.children).reduce((accumulator, node) => {
    const { modal, ...config } = node.dataset;

    return {
      ...accumulator,
      [modal]: {
        title: node.dataset.title,
        ...config,
        content: node.innerHTML,
      },
    };
  }, {});

  // eslint-disable-next-line no-new
  new Vue({
    el: MODAL_MANAGER_SELECTOR,
    functional: true,
    methods: {
      show(...args) {
        this.$refs.manager.show(...args);
      },
    },
    render(h) {
      return h(ModalManager, {
        ref: 'manager',
        props: {
          selector: CONFIRM_DELETE_BUTTON_SELECTOR,
          modalConfiguration,
          csrfToken: csrf.token,
        },
      });
    },
  });
};
