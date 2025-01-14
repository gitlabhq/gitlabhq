import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlSkeletonLoader, GlTab, GlPagination } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EnvironmentsFolderAppComponent from '~/environments/folder/environments_folder_app.vue';
import EnvironmentItem from '~/environments/components/new_environment_item.vue';
import StopEnvironmentModal from '~/environments/components/stop_environment_modal.vue';
import ConfirmRollbackModal from '~/environments/components/confirm_rollback_modal.vue';
import DeleteEnvironmentModal from '~/environments/components/delete_environment_modal.vue';
import CanaryUpdateModal from '~/environments/components/canary_update_modal.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  resolvedFolder,
  resolvedEnvironment,
  resolvedEnvironmentToDelete,
  resolvedEnvironmentToRollback,
} from '../graphql/mock_data';

Vue.use(VueApollo);

describe('EnvironmentsFolderAppComponent', () => {
  let wrapper;
  const mockFolderName = 'folders';

  let environmentFolderMock;

  const createApolloProvider = () => {
    const mockResolvers = {
      Query: {
        folder: environmentFolderMock,
        environmentToDelete: jest.fn().mockReturnValue(resolvedEnvironmentToDelete),
        environmentToRollback: jest.fn().mockReturnValue(resolvedEnvironment),
        environmentToChangeCanary: jest.fn().mockReturnValue(resolvedEnvironment),
        environmentToStop: jest.fn().mockReturnValue(resolvedEnvironment),
        weight: jest.fn().mockReturnValue(1),
      },
    };

    return createMockApollo([], mockResolvers);
  };

  beforeEach(() => {
    environmentFolderMock = jest.fn();
  });

  const emptyFolderData = {
    environments: [],
    activeCount: 0,
    stoppedCount: 0,
    __typename: 'LocalEnvironmentFolder',
  };

  const createWrapper = ({ folderData } = {}) => {
    environmentFolderMock.mockReturnValue(folderData || emptyFolderData);

    const apolloProvider = createApolloProvider();

    wrapper = shallowMountExtended(EnvironmentsFolderAppComponent, {
      apolloProvider,
      propsData: {
        folderName: mockFolderName,
        folderPath: '/gitlab-org/test-project/-/environments/folder/dev',
        scope: 'active',
        page: 1,
      },
    });
  };

  const findHeader = () => wrapper.findByTestId('folder-name');
  const findEnvironmentItems = () => wrapper.findAllComponents(EnvironmentItem);
  const findSkeletonLoaders = () => wrapper.findAllComponents(GlSkeletonLoader);
  const findTabs = () => wrapper.findAllComponents(GlTab);

  it('should render a header with the folder name', () => {
    createWrapper();

    expect(findHeader().text()).toMatchInterpolatedText(`Environments / ${mockFolderName}`);
  });

  it('should show skeletons while loading', () => {
    createWrapper();
    expect(findSkeletonLoaders().length).toBe(3);
  });

  describe('when environments are loaded', () => {
    beforeEach(async () => {
      createWrapper({ folderData: resolvedFolder });
      await waitForPromises();
    });

    it('should list environments in folder', () => {
      const items = findEnvironmentItems();
      expect(items.length).toBe(resolvedFolder.environments.length);
    });

    it('should render active and stopped tabs', () => {
      const tabs = findTabs();
      expect(tabs.length).toBe(2);
    });

    [
      [StopEnvironmentModal, resolvedEnvironment],
      [DeleteEnvironmentModal, resolvedEnvironmentToDelete],
      [ConfirmRollbackModal, resolvedEnvironmentToRollback],
    ].forEach(([Component, expectedEnvironment]) =>
      it(`should render ${Component.name} component`, () => {
        const modal = wrapper.findComponent(Component);

        expect(modal.exists()).toBe(true);
        expect(modal.props().environment).toEqual(expectedEnvironment);
        expect(modal.props().graphql).toBe(true);
      }),
    );

    it(`should render CanaryUpdateModal component`, () => {
      const modal = wrapper.findComponent(CanaryUpdateModal);

      expect(modal.exists()).toBe(true);
      expect(modal.props().environment).toEqual(resolvedEnvironment);
      expect(modal.props().weight).toBe(1);
    });

    it('should render pagination component', () => {
      const pagination = wrapper.findComponent(GlPagination);

      expect(pagination.props().perPage).toBe(20);
      expect(pagination.props().totalItems).toBe(2);
    });
  });
});
