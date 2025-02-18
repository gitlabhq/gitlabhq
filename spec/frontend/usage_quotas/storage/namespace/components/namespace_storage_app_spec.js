import { GlAlert } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { cloneDeep } from 'lodash';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { captureException } from '~/ci/runner/sentry_utils';
import NamespaceStorageApp from '~/usage_quotas/storage/namespace/components/namespace_storage_app.vue';
import ProjectList from '~/usage_quotas/storage/namespace/components/project_list.vue';
import getNamespaceStorageQuery from 'ee_else_ce/usage_quotas/storage/namespace/queries/namespace_storage.query.graphql';
import getProjectListStorageQuery from 'ee_else_ce/usage_quotas/storage/namespace/queries/project_list_storage.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import SearchAndSortBar from '~/usage_quotas/components/search_and_sort_bar/search_and_sort_bar.vue';
import StorageUsageStatistics from '~/usage_quotas/storage/namespace/components/storage_usage_statistics.vue';
import DependencyProxyUsage from '~/usage_quotas/storage/namespace/components/dependency_proxy_usage.vue';
import ContainerRegistryUsage from '~/usage_quotas/storage/namespace/components/container_registry_usage.vue';
import {
  namespace,
  defaultNamespaceProvideValues,
  mockGetNamespaceStorageGraphQLResponse,
  mockGetProjectListStorageGraphQLResponse,
} from '../../mock_data';

jest.mock('~/ci/runner/sentry_utils');

Vue.use(VueApollo);

describe('NamespaceStorageApp', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const getNamespaceStorageHandler = jest.fn();
  const getProjectListStorageHandler = jest.fn();

  const findStorageUsageStatistics = () => wrapper.findComponent(StorageUsageStatistics);
  const findDependencyProxy = () => wrapper.findComponent(DependencyProxyUsage);
  const findContainerRegistry = () => wrapper.findComponent(ContainerRegistryUsage);
  const findBreakdownSubtitle = () => wrapper.findByTestId('breakdown-subtitle');
  const findSearchAndSortBar = () => wrapper.findComponent(SearchAndSortBar);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findProjectList = () => wrapper.findComponent(ProjectList);
  const findPrevButton = () => wrapper.findByTestId('prevButton');
  const findNextButton = () => wrapper.findByTestId('nextButton');

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = mountExtended(NamespaceStorageApp, {
      apolloProvider: createMockApollo([
        [getNamespaceStorageQuery, getNamespaceStorageHandler],
        [getProjectListStorageQuery, getProjectListStorageHandler],
      ]),
      provide: {
        ...defaultNamespaceProvideValues,
        ...provide,
      },
    });
  };

  beforeEach(() => {
    getNamespaceStorageHandler.mockResolvedValue(mockGetNamespaceStorageGraphQLResponse);
    getProjectListStorageHandler.mockResolvedValue(mockGetProjectListStorageGraphQLResponse);
  });

  describe('Namespace usage overview', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    describe('StorageUsageStatistics', () => {
      it('passes the correct props to StorageUsageStatistics', () => {
        expect(findStorageUsageStatistics().props()).toMatchObject({
          usedStorage: namespace.rootStorageStatistics.storageSize,
          loading: false,
        });
      });

      it('displays loading state', () => {
        getNamespaceStorageHandler.mockImplementation(() => new Promise(() => {}));
        createComponent();
        expect(findStorageUsageStatistics().props('loading')).toBe(true);
      });
    });

    describe('Storage usage breakdown', () => {
      it('shows the namespace storage breakdown subtitle', () => {
        expect(findBreakdownSubtitle().text()).toBe('Storage usage breakdown');
      });

      describe('Dependency proxy usage', () => {
        it('shows the dependency proxy usage component', async () => {
          createComponent({
            provide: { userNamespace: false },
          });
          await waitForPromises();

          expect(findDependencyProxy().exists()).toBe(true);
        });

        it('does not display the dependency proxy for personal namespaces', async () => {
          createComponent({
            provide: { userNamespace: true },
          });
          await waitForPromises();

          expect(findDependencyProxy().exists()).toBe(false);
        });
      });

      describe('ContainerRegistryUsage', () => {
        it('will be rendered', () => {
          expect(findContainerRegistry().exists()).toBe(true);
        });

        it('will receive relevant props', () => {
          const { containerRegistrySize, containerRegistrySizeIsEstimated } =
            namespace.rootStorageStatistics;

          expect(findContainerRegistry().props()).toEqual({
            containerRegistrySize,
            containerRegistrySizeIsEstimated,
            loading: false,
          });
        });
      });
    });
  });

  describe('Namespace project list', () => {
    it('renders the 2 projects', async () => {
      createComponent();
      await waitForPromises();

      expect(findProjectList().props('projects')).toHaveLength(2);
    });

    describe('filtering projects', () => {
      const sampleSearchTerm = 'GitLab';

      beforeEach(() => {
        createComponent();
      });

      it('triggers search if user enters search input', async () => {
        expect(getProjectListStorageHandler).toHaveBeenNthCalledWith(
          1,
          expect.objectContaining({ searchTerm: '' }),
        );
        findSearchAndSortBar().vm.$emit('onFilter', sampleSearchTerm);
        await waitForPromises();

        expect(getProjectListStorageHandler).toHaveBeenNthCalledWith(
          2,
          expect.objectContaining({ searchTerm: sampleSearchTerm }),
        );
      });

      it('triggers search if user clears the entered search input', async () => {
        findSearchAndSortBar().vm.$emit('onFilter', sampleSearchTerm);
        await waitForPromises();

        expect(getProjectListStorageHandler).toHaveBeenCalledWith(
          expect.objectContaining({ searchTerm: sampleSearchTerm }),
        );

        findSearchAndSortBar().vm.$emit('onFilter', '');
        await waitForPromises();

        expect(getProjectListStorageHandler).toHaveBeenCalledWith(
          expect.objectContaining({ searchTerm: '' }),
        );
      });

      it('triggers search with empty string if user enters short search input', async () => {
        findSearchAndSortBar().vm.$emit('onFilter', sampleSearchTerm);
        await waitForPromises();
        expect(getProjectListStorageHandler).toHaveBeenCalledWith(
          expect.objectContaining({ searchTerm: sampleSearchTerm }),
        );

        const sampleShortSearchTerm = 'Gi';
        findSearchAndSortBar().vm.$emit('onFilter', sampleShortSearchTerm);
        await waitForPromises();

        expect(getProjectListStorageHandler).toHaveBeenCalledWith(
          expect.objectContaining({ searchTerm: '' }),
        );
      });
    });

    describe('projects table pagination component', () => {
      const projectsStorageWithPageInfo = cloneDeep(mockGetProjectListStorageGraphQLResponse);
      projectsStorageWithPageInfo.data.namespace.projects.pageInfo.hasNextPage = true;

      beforeEach(() => {
        getProjectListStorageHandler.mockResolvedValue(projectsStorageWithPageInfo);
      });

      it('has "Prev" button disabled', async () => {
        createComponent();
        await waitForPromises();

        expect(findPrevButton().attributes().disabled).toBe('disabled');
      });

      it('has "Next" button enabled', async () => {
        createComponent();
        await waitForPromises();

        expect(findNextButton().attributes().disabled).toBeUndefined();
      });

      describe('apollo calls', () => {
        beforeEach(async () => {
          projectsStorageWithPageInfo.data.namespace.projects.pageInfo.hasPreviousPage = true;
          createComponent();

          await waitForPromises();
        });

        it('contains correct `first` and `last` values when clicking "Prev" button', () => {
          findPrevButton().trigger('click');
          expect(getProjectListStorageHandler).toHaveBeenCalledTimes(2);
          expect(getProjectListStorageHandler).toHaveBeenNthCalledWith(
            2,
            expect.objectContaining({ first: undefined, last: expect.any(Number) }),
          );
        });

        it('contains `first` value when clicking "Next" button', () => {
          findNextButton().trigger('click');
          expect(getProjectListStorageHandler).toHaveBeenCalledTimes(2);
          expect(getProjectListStorageHandler).toHaveBeenNthCalledWith(
            2,
            expect.objectContaining({ first: expect.any(Number) }),
          );
        });
      });

      describe('handling failed apollo requests', () => {
        beforeEach(async () => {
          getProjectListStorageHandler.mockRejectedValue(new Error('Network error!'));
          createComponent();
          await waitForPromises();
        });

        it('shows gl-alert with error message', () => {
          expect(findAlert().exists()).toBe(true);
          expect(findAlert().text()).toBe(
            'An error occured while loading the storage usage details. Please refresh the page to try again.',
          );
        });

        it('captures the exception in Sentry', async () => {
          await Vue.nextTick();
          expect(captureException).toHaveBeenCalledTimes(1);
        });
      });
    });
  });
});
