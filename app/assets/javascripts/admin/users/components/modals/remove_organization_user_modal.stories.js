import createMockApollo from 'helpers/mock_apollo_helper';
import removeOrganizationUserMutation from '~/admin/users/graphql/mutations/remove_organization_user.mutation.graphql';
import RemoveOrganizationUserModal from './remove_organization_user_modal.vue';
import eventHub, {
  EVENT_OPEN_REMOVE_FROM_ORGANIZATION_MODAL,
} from './remove_from_organization_modal_event_hub';

export default {
  component: RemoveOrganizationUserModal,
  title: 'admin/users/components/modals/remove_organization_user_modal',
};

const Template = (args) => ({
  components: { RemoveOrganizationUserModal },
  apolloProvider: createMockApollo([
    [
      removeOrganizationUserMutation,
      () => Promise.resolve({ data: { organizationUserDelete: { errors: [] } } }),
    ],
  ]),
  mounted() {
    eventHub.$emit(EVENT_OPEN_REMOVE_FROM_ORGANIZATION_MODAL, {
      username: args.username,
      organizationUserGid: args.organizationUserGid,
    });
  },
  template: '<remove-organization-user-modal />',
});

export const Default = Template.bind({});
Default.args = {
  username: 'John Doe',
  organizationUserGid: 'gid://gitlab/Organizations::OrganizationUser/1',
};
