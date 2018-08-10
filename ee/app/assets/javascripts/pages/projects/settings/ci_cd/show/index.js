import Vue from 'vue';
import Dashboard from 'ee/vue_shared/license_management/license_management.vue';
import ProtectedEnvironmentCreate from 'ee/protected_environments/protected_environment_create';
import ProtectedEnvironmentEditList from 'ee/protected_environments/protected_environment_edit_list';
import '~/pages/projects/settings/ci_cd/show/index';

document.addEventListener('DOMContentLoaded', () => {
  const el = document.getElementById('js-managed-licenses');

  if (el && el.dataset && el.dataset.apiUrl) {
    // eslint-disable-next-line no-new
    new Vue({
      el,
      render(createElement) {
        return createElement(Dashboard, {
          props: {
            ...el.dataset,
          },
        });
      },
    });
  }

  // eslint-disable-next-line no-new
  new ProtectedEnvironmentCreate();

  // eslint-disable-next-line no-new
  new ProtectedEnvironmentEditList();
});
