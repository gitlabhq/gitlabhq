import { GlButton } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import removeOrganizationUserMutation from '~/admin/users/graphql/mutations/remove_organization_user.mutation.graphql';
import soloOwnedGroupsQuery from '~/organizations/shared/graphql/queries/solo_owned_groups.query.graphql';
import RemoveOrganizationUserModal from './remove_organization_user_modal.vue';
import eventHub, {
  EVENT_OPEN_REMOVE_FROM_ORGANIZATION_MODAL,
} from './remove_from_organization_modal_event_hub';

export default {
  component: RemoveOrganizationUserModal,
  title: 'admin/users/components/modals/remove_organization_user_modal',
};

const createGroups = (count) =>
  Array.from({ length: count }, (_, index) => ({
    id: `gid://gitlab/Group/${index + 1}`,
    fullPath: index === 0 ? 'acme' : `acme/group-${index}`,
    webPath: '#',
    parent: index === 0 ? null : { id: 'gid://gitlab/Group/1' },
  }));

const soloOwnedGroupsHandler =
  (count) =>
  ({ first, after }) => {
    const start = after ? Number(after) : 0;
    const end = Math.min(start + first, count);

    return Promise.resolve({
      data: {
        user: {
          id: 'gid://gitlab/User/1',
          groups: {
            count,
            nodes: createGroups(count).slice(start, end),
            pageInfo: { hasNextPage: end < count, endCursor: String(end) },
          },
        },
      },
    });
  };

const Template = (args) => ({
  components: { GlButton, RemoveOrganizationUserModal },
  apolloProvider: createMockApollo([
    [soloOwnedGroupsQuery, soloOwnedGroupsHandler(args.soloOwnedGroupsCount)],
    [
      removeOrganizationUserMutation,
      () => Promise.resolve({ data: { organizationUserDelete: { errors: [] } } }),
    ],
  ]),
  methods: {
    openModal() {
      eventHub.$emit(EVENT_OPEN_REMOVE_FROM_ORGANIZATION_MODAL, {
        username: args.username,
        userId: 1,
        organizationUserGid: args.organizationUserGid,
      });
    },
  },
  template: `
    <div>
      <gl-button @click="openModal">Open modal</gl-button>
      <remove-organization-user-modal />
    </div>
  `,
});

export const Default = Template.bind({});
Default.args = {
  username: 'John Doe',
  organizationUserGid: 'gid://gitlab/Organizations::OrganizationUser/1',
  soloOwnedGroupsCount: 7,
};
