import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import AdminUsersApp from './components/app.vue';

export const initAdminUsersApp = (el = document.querySelector('#js-admin-users-app')) => {
  if (!el) {
    return false;
  }

  const { users, paths } = el.dataset;

  return new Vue({
    el,
    render: (createElement) =>
      createElement(AdminUsersApp, {
        props: {
          users: convertObjectPropsToCamelCase(JSON.parse(users), { deep: true }),
          paths: convertObjectPropsToCamelCase(JSON.parse(paths)),
        },
      }),
  });
};
