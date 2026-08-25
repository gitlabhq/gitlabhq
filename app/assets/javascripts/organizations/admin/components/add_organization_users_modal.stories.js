import AddOrganizationUsersModal from './add_organization_users_modal.vue';

export default {
  component: AddOrganizationUsersModal,
  title: 'organizations/admin/components/add_organization_users_modal',
  provide: {
    organizationGid: 'gid://gitlab/Organizations::Organization/1',
    organizationName: 'GitLab',
    searchUrl: '/-/autocomplete/users.json',
  },
};

const Template = (args) => ({
  components: { AddOrganizationUsersModal },
  props: Object.keys(args),
  template: `<add-organization-users-modal :visible="visible" />`,
});

export const Default = Template.bind({});
Default.args = {
  visible: true,
};
