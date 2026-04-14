import createMockApollo from 'helpers/mock_apollo_helper';
import currentUserNamespace from '~/projects/settings/graphql/queries/current_user_namespace.query.graphql';
import TransferProjectModal from './transfer_modal.vue';

const mockGetTransferLocations = () => {
  return Promise.resolve({
    data: [
      { id: 2, full_name: 'New Namespace', full_path: 'new-namespace' },
      { id: 3, full_name: 'Another Group', full_path: 'another-group' },
      { id: 4, full_name: 'Third Group', full_path: 'third-group' },
    ],
    headers: {
      'x-total-pages': '1',
    },
  });
};

const mockTransferProject = () => {
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
    TransferProjectModal: {
      ...TransferProjectModal,
      getTransferLocations: mockGetTransferLocations,
      transferProject: mockTransferProject,
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
      <transfer-project-modal
        v-bind="$props"
        :visible="isVisible"
        @change="isVisible = $event"
      />
    </div>
  `,
});

export default {
  component: TransferProjectModal,
  title: 'projects/transfer_modal',
};

export const ProjectInGroup = Template.bind({});
ProjectInGroup.args = {
  visible: false,
  project: {
    id: 1,
    name: 'My Project',
    path: 'my-project',
    fullPath: 'group/my-project',
  },
};

export const ProjectInUserNamespace = Template.bind({});
ProjectInUserNamespace.args = {
  visible: false,
  project: {
    id: 2,
    name: 'Personal Project',
    path: 'personal-project',
    fullPath: 'username/personal-project',
  },
};
