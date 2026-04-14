import createMockApollo from 'helpers/mock_apollo_helper';
import currentUserNamespace from '~/projects/settings/graphql/queries/current_user_namespace.query.graphql';
import GroupsProjectsTransferModal from './transfer_modal.vue';

const mockGroupTransferLocationsApiMethod = () => {
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

const mockTransferApiMethod = () => {
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
  components: { GroupsProjectsTransferModal },
  apolloProvider: createApolloProvider(),
  props: Object.keys(argTypes),
  provide: {
    resourceId: '1',
    resourcePath: 'test-group',
    resourceFullPath: 'parent/test-group',
  },
  data() {
    return {
      isVisible: args.visible,
    };
  },
  template: `
    <div>
      <button @click="isVisible = true">Open Transfer Modal</button>
      <groups-projects-transfer-modal
        v-bind="$props"
        :visible="isVisible"
        @change="isVisible = $event"
      >
        <template #body>
          <p>Transfer this group to a different namespace.</p>
        </template>
      </groups-projects-transfer-modal>
    </div>
  `,
});

export default {
  component: GroupsProjectsTransferModal,
  title: 'groups_projects/transfer_modal',
};

export const Default = Template.bind({});
Default.args = {
  visible: false,
  title: 'Transfer group',
  groupTransferLocationsApiMethod: mockGroupTransferLocationsApiMethod,
  transferApiMethod: mockTransferApiMethod,
  showUserTransferLocations: true,
  additionalDropdownItems: [],
};

export const WithAdditionalItems = Template.bind({});
WithAdditionalItems.args = {
  ...Default.args,
  additionalDropdownItems: [
    { id: -1, humanName: 'No parent', newPath: 'test-group' },
    { id: -2, humanName: 'Special option' },
  ],
};

export const WithoutUserLocations = Template.bind({});
WithoutUserLocations.args = {
  ...Default.args,
  showUserTransferLocations: false,
};
