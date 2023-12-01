import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EnvironmentsFolderAppComponent from '~/environments/folder/environments_folder_app.vue';
import EnvironmentItem from '~/environments/components/new_environment_item.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { resolvedFolder } from '../graphql/mock_data';

Vue.use(VueApollo);

describe('EnvironmentsFolderAppComponent', () => {
  let wrapper;
  const mockFolderName = 'folders';

  let environmentFolderMock;

  const createApolloProvider = () => {
    const mockResolvers = {
      Query: {
        folder: environmentFolderMock,
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
      },
    });
  };

  const findHeader = () => wrapper.findByTestId('folder-name');
  const findEnvironmentItems = () => wrapper.findAllComponents(EnvironmentItem);
  const findSkeletonLoaders = () => wrapper.findAllComponents(GlSkeletonLoader);

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

    it('should list environmnets in folder', () => {
      const items = findEnvironmentItems();
      expect(items.length).toBe(resolvedFolder.environments.length);
    });
  });
});
