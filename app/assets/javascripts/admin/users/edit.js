import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import NewUserOrganizationField from './components/new_user_organization_field.vue';

export const initAdminNewUserOrganizationField = () => {
  const el = document.getElementById('js-admin-edit-user-organization-field');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;

  const { initialAccessLevel, initialOrganization } = convertObjectPropsToCamelCase(
    JSON.parse(appData),
    { deep: true },
  );

  return new Vue({
    el,
    name: 'AdminEditUserOrganizationFieldRoot',
    render(createElement) {
      return createElement(NewUserOrganizationField, {
        props: {
          initialAccessLevel,
          initialOrganization,
          hasMultipleOrganizations: false,
          organizationInputName: 'user[organization_user][][organization_id]',
          organizationRoleInputName: 'user[organization_user][][access_level]',
        },
      });
    },
  });
};
