import createMockApollo from 'helpers/mock_apollo_helper';
import currentUserNamespace from '~/projects/settings/graphql/queries/current_user_namespace.query.graphql';
import TransferGroupModal from './transfer_modal.vue';

const mockGetGroupTransferLocations = () => {
  return Promise.resolve({
    data: [
      { id: 2, full_name: 'New Parent Group', full_path: 'new-parent' },
      { id: 3, full_name: 'Another Group', full_path: 'another-group' },
      { id: 4, full_name: 'Third Group', full_path: 'third-group' },
    ],
    headers: {
      'x-total-pages': '1',
    },
  });
};

const mockTransferGroup = () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({});
    }, 1000);
  });
};

const currentUserNamespaceQueryHandler = () => ({
  data: {
    currentUser: {
      id: 'gid://gitlab/User/1',
      username: 'root',
      namespace: {
        id: 'gid://gitlab/Namespace/1',
        fullName: 'Administrator',
        fullPath: 'root',
      },
    },
  },
});

const createApolloProvider = () => {
  return createMockApollo([[currentUserNamespace, currentUserNamespaceQueryHandler]]);
};

const Template = (args, { argTypes }) => ({
  components: {
    TransferGroupModal: {
      ...TransferGroupModal,
      getGroupTransferLocations: mockGetGroupTransferLocations,
      transferGroup: mockTransferGroup,
    },
  },
  apolloProvider: createApolloProvider(),
  props: Object.keys(argTypes),
  data() {
    return {
      isVisible: args.visible,
    };
  },
  template: `
    <div>
      <button @click="isVisible = true">Open Transfer Modal</button>
      <transfer-group-modal
        v-bind="$props"
        :visible="isVisible"
        @change="isVisible = $event"
      />
    </div>
  `,
});

export default {
  component: TransferGroupModal,
  title: 'groups/transfer_modal',
};

export const NestedGroup = Template.bind({});
NestedGroup.args = {
  visible: false,
  group: {
    id: 1,
    name: 'My Subgroup',
    path: 'my-subgroup',
    fullPath: 'parent/my-subgroup',
  },
};

export const TopLevelGroup = Template.bind({});
TopLevelGroup.args = {
  visible: false,
  group: {
    id: 2,
    name: 'Top Level Group',
    path: 'top-level-group',
    fullPath: 'top-level-group',
  },
};
