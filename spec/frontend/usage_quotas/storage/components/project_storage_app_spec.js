import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ProjectStorageApp from '~/usage_quotas/storage/components/project_storage_app.vue';
import UsageGraph from '~/usage_quotas/storage/components/usage_graph.vue';
import { TOTAL_USAGE_DEFAULT_TEXT } from '~/usage_quotas/storage/constants';
import getProjectStorageStatistics from '~/usage_quotas/storage/queries/project_storage.query.graphql';
import {
  projectData,
  mockGetProjectStorageStatisticsGraphQLResponse,
  mockEmptyResponse,
  defaultProjectProvideValues,
} from '../mock_data';

Vue.use(VueApollo);

describe('ProjectStorageApp', () => {
  let wrapper;

  const createMockApolloProvider = ({ reject = false, mockedValue } = {}) => {
    let response;

    if (reject) {
      response = jest.fn().mockRejectedValue(mockedValue || new Error('GraphQL error'));
    } else {
      response = jest.fn().mockResolvedValue(mockedValue);
    }

    const requestHandlers = [[getProjectStorageStatistics, response]];

    return createMockApollo(requestHandlers);
  };

  const createComponent = ({ provide = {}, mockApollo } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(ProjectStorageApp, {
        apolloProvider: mockApollo,
        provide: {
          ...defaultProjectProvideValues,
          ...provide,
        },
      }),
    );
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findUsagePercentage = () => wrapper.findByTestId('total-usage');
  const findUsageQuotasHelpLink = () => wrapper.findByTestId('usage-quotas-help-link');
  const findUsageGraph = () => wrapper.findComponent(UsageGraph);

  describe('with apollo fetching successful', () => {
    let mockApollo;

    beforeEach(async () => {
      mockApollo = createMockApolloProvider({
        mockedValue: mockGetProjectStorageStatisticsGraphQLResponse,
      });
      createComponent({ mockApollo });
      await waitForPromises();
    });

    it('renders correct total usage', () => {
      expect(findUsagePercentage().text()).toBe(projectData.storage.totalUsage);
    });

    it('renders correct usage quotas help link', () => {
      expect(findUsageQuotasHelpLink().attributes('href')).toBe(
        defaultProjectProvideValues.helpLinks.usageQuotas,
      );
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
      expect(findUsagePercentage().text()).toBe(TOTAL_USAGE_DEFAULT_TEXT);
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

  describe('rendering <usage-graph />', () => {
    let mockApollo;

    beforeEach(async () => {
      mockApollo = createMockApolloProvider({
        mockedValue: mockGetProjectStorageStatisticsGraphQLResponse,
      });
      createComponent({ mockApollo });
      await waitForPromises();
    });

    it('renders usage-graph component if project.statistics exists', () => {
      expect(findUsageGraph().exists()).toBe(true);
    });

    it('passes project.statistics to usage-graph component', () => {
      const {
        __typename,
        ...statistics
      } = mockGetProjectStorageStatisticsGraphQLResponse.data.project.statistics;
      expect(findUsageGraph().props('rootStorageStatistics')).toMatchObject(statistics);
    });
  });
});
