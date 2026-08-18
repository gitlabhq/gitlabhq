import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import NewUserOrganizationField from './components/new_user_organization_field.vue';

export const initAdminNewUserOrganizationField = () => {
  const el = document.getElementById('js-admin-edit-user-organization-field');

  if (!el) return false;

  const {
    dataset: { appData },
  } = el;

  const { organizationUser, initialOrganization } = convertObjectPropsToCamelCase(
    JSON.parse(appData),
    { deep: true },
  );

  return initVueApp({
    el,
    name: 'AdminEditUserOrganizationFieldRoot',
    component: NewUserOrganizationField,
    props: {
      organizationUser,
      initialOrganization,
      hasMultipleOrganizations: false,
      organizationInputName: 'user[organization_users_attributes][][organization_id]',
      organizationRoleInputName: 'user[organization_users_attributes][][access_level]',
    },
  });
};
