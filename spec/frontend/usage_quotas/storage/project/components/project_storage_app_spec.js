import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getPreferredLocales } from '~/locale';
import ProjectStorageApp from '~/usage_quotas/storage/project/components/project_storage_app.vue';
import SectionedPercentageBar from '~/usage_quotas/components/sectioned_percentage_bar.vue';
import {
  descendingStorageUsageSort,
  getStorageTypesFromProjectStatistics,
} from '~/usage_quotas/storage/project/utils';
import { storageTypeHelpPaths } from '~/usage_quotas/storage/constants';
import {
  PROJECT_STORAGE_TYPES,
  NAMESPACE_STORAGE_TYPES,
} from '~/usage_quotas/storage/project/constants';
import getCostFactoredProjectStorageStatistics from 'ee_else_ce/usage_quotas/storage/project/queries/cost_factored_project_storage.query.graphql';
import getProjectStorageStatistics from 'ee_else_ce/usage_quotas/storage/project/queries/project_storage.query.graphql';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import {
  mockGetProjectStorageStatisticsGraphQLResponse,
  mockEmptyResponse,
  defaultProjectProvideValues,
} from '../../mock_data';

Vue.use(VueApollo);

jest.mock('~/locale', () => ({
  ...jest.requireActual('~/locale'),
  getPreferredLocales: jest.fn(),
}));

describe('ProjectStorageApp', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const createMockApolloProvider = ({ reject = false, mockedValue } = {}) => {
    let response;

    if (reject) {
      response = jest.fn().mockRejectedValue(mockedValue || new Error('GraphQL error'));
    } else {
      response = jest.fn().mockResolvedValue(mockedValue);
    }

    const requestHandlers = [
      [getProjectStorageStatistics, response],
      [getCostFactoredProjectStorageStatistics, response],
    ];

    return createMockApollo(requestHandlers);
  };

  const createComponent = ({ provide = {}, mockApollo } = {}) => {
    wrapper = shallowMountExtended(ProjectStorageApp, {
      apolloProvider: mockApollo,
      provide: {
        ...defaultProjectProvideValues,
        ...provide,
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findUsagePercentage = () => wrapper.findByTestId('total-usage');
  const findSectionedPercentageBar = () => wrapper.findComponent(SectionedPercentageBar);
  const findProjectDetailsTable = () => wrapper.findByTestId('usage-quotas-project-usage-details');
  const findNamespaceDetailsTable = () =>
    wrapper.findByTestId('usage-quotas-namespace-usage-details');

  describe('with apollo fetching successful', () => {
    let mockApollo;
    const mockProjectData = mockGetProjectStorageStatisticsGraphQLResponse.data.project;

    beforeEach(async () => {
      getPreferredLocales.mockImplementation(() => ['en']);
      mockApollo = createMockApolloProvider({
        mockedValue: mockGetProjectStorageStatisticsGraphQLResponse,
      });
      createComponent({ mockApollo });
      await waitForPromises();
    });

    it('renders correct total usage', () => {
      const expectedValue = numberToHumanSize(
        mockGetProjectStorageStatisticsGraphQLResponse.data.project.statistics.storageSize,
        1,
      );
      expect(findUsagePercentage().text()).toBe(expectedValue);
    });

    it('passes project storage entities to project details table', () => {
      const expectedValue = getStorageTypesFromProjectStatistics(
        PROJECT_STORAGE_TYPES,
        mockProjectData.statistics,
        mockProjectData.statisticsDetailsPaths,
        storageTypeHelpPaths,
      ).sort(descendingStorageUsageSort('value'));

      expect(findProjectDetailsTable().props('storageTypes')).toStrictEqual(expectedValue);
    });

    it('passes namespace storage entities to namespace details table', () => {
      const expectedValue = getStorageTypesFromProjectStatistics(
        NAMESPACE_STORAGE_TYPES,
        mockProjectData.statistics,
        mockProjectData.statisticsDetailsPaths,
        storageTypeHelpPaths,
      );

      expect(findNamespaceDetailsTable().props('storageTypes')).toStrictEqual(expectedValue);
    });

    describe('with a different locale', () => {
      beforeEach(() => {
        getPreferredLocales.mockImplementation(() => ['it']);
        mockApollo = createMockApolloProvider({
          mockedValue: mockGetProjectStorageStatisticsGraphQLResponse,
        });
        createComponent({ mockApollo });
        return waitForPromises();
      });

      it('passes namespace storage entities to namespace details table', () => {
        const expectedValue = numberToHumanSize(
          mockGetProjectStorageStatisticsGraphQLResponse.data.project.statistics.storageSize,
          1,
          ['it'],
        );

        expect(findUsagePercentage().text()).toBe(expectedValue);
      });
    });
  });

  describe('with apollo loading', () => {
    let mockApollo;

    beforeEach(() => {
      mockApollo = createMockApolloProvider({
        mockedValue: new Promise(() => {}),
      });
      createComponent({ mockApollo });
    });

    it('should show loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('with apollo returning empty data', () => {
    let mockApollo;

    beforeEach(async () => {
      mockApollo = createMockApolloProvider({
        mockedValue: mockEmptyResponse,
      });
      createComponent({ mockApollo });
      await waitForPromises();
    });

    it('shows default text for total usage', () => {
      expect(findUsagePercentage().text()).toBe('Not applicable.');
    });

    it('passes empty array to project details table', () => {
      expect(findProjectDetailsTable().props('storageTypes')).toStrictEqual([]);
    });

    it('passes empty array to namespace details table', () => {
      expect(findNamespaceDetailsTable().props('storageTypes')).toStrictEqual([]);
    });
  });

  describe('with apollo fetching error', () => {
    let mockApollo;

    beforeEach(async () => {
      mockApollo = createMockApolloProvider();
      createComponent({ mockApollo, reject: true });
      await waitForPromises();
    });

    it('renders gl-alert', () => {
      expect(findAlert().exists()).toBe(true);
    });
  });

  describe('rendering <sectioned-percentage-bar />', () => {
    let mockApollo;

    beforeEach(async () => {
      mockApollo = createMockApolloProvider({
        mockedValue: mockGetProjectStorageStatisticsGraphQLResponse,
      });
      createComponent({ mockApollo });
      await waitForPromises();
    });

    it('renders sectioned-percentage-bar component if project.statistics exists', () => {
      expect(findSectionedPercentageBar().exists()).toBe(true);
    });

    it('passes processed project statistics to sectioned-percentage-bar component', () => {
      expect(findSectionedPercentageBar().props('sections')).toMatchObject([
        { formattedValue: '4.58 MiB', id: 'lfsObjects', label: 'LFS', value: 4800000 },
        { formattedValue: '3.72 MiB', id: 'repository', label: 'Repository', value: 3900000 },
        { formattedValue: '3.62 MiB', id: 'packages', label: 'Packages', value: 3800000 },
        {
          formattedValue: '390.63 KiB',
          id: 'buildArtifacts',
          label: 'Job artifacts',
          value: 400000,
        },
        { formattedValue: '292.97 KiB', id: 'wiki', label: 'Wiki', value: 300000 },
      ]);
    });
  });

  describe('when displayCostFactoredStorageSizeOnProjectPages feature flag is enabled', () => {
    let mockApollo;
    beforeEach(async () => {
      getPreferredLocales.mockImplementation(() => ['en']);
      mockApollo = createMockApolloProvider({
        mockedValue: mockGetProjectStorageStatisticsGraphQLResponse,
      });
      createComponent({
        mockApollo,
        provide: {
          glFeatures: {
            displayCostFactoredStorageSizeOnProjectPages: true,
          },
        },
      });
      await waitForPromises();
    });

    it('renders correct total usage', () => {
      const expectedValue = numberToHumanSize(
        mockGetProjectStorageStatisticsGraphQLResponse.data.project.statistics.storageSize,
        1,
      );
      expect(findUsagePercentage().text()).toBe(expectedValue);
    });
  });
});
