import { GlLoadingIcon, GlAlert, GlEmptyState } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useFakeDate } from 'helpers/fake_date';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ActivityEvents from '~/clusters/agents/components/activity_events_list.vue';
import ActivityHistoryItem from '~/clusters/agents/components/activity_history_item.vue';
import getAgentActivityEventsQuery from '~/clusters/agents/graphql/queries/get_agent_activity_events.query.graphql';
import { mockResponse, mockEmptyResponse } from '../../mock_data';

const activityEmptyStateImage = '/path/to/image';
const projectPath = 'path/to/project';
const agentName = 'cluster-agent';

Vue.use(VueApollo);

describe('ActivityEvents', () => {
  let wrapper;
  useFakeDate([2021, 12, 3]);

  const provideData = {
    agentName,
    projectPath,
    activityEmptyStateImage,
  };

  const createWrapper = ({ queryResponse = null } = {}) => {
    const agentEventsQueryResponse = queryResponse || jest.fn().mockResolvedValue(mockResponse);
    const apolloProvider = createMockApollo([
      [getAgentActivityEventsQuery, agentEventsQueryResponse],
    ]);

    wrapper = shallowMountExtended(ActivityEvents, {
      apolloProvider,
      provide: provideData,
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findAllActivityHistoryItems = () => wrapper.findAllComponents(ActivityHistoryItem);
  const findSectionTitle = (at) => wrapper.findAllByTestId('activity-section-title').at(at);

  describe('while the agentEvents query is loading', () => {
    it('displays a loading icon', async () => {
      createWrapper();

      expect(findLoadingIcon().exists()).toBe(true);
      await waitForPromises();
      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('when the agentEvents query has errored', () => {
    beforeEach(() => {
      createWrapper({ queryResponse: jest.fn().mockRejectedValue() });
      return waitForPromises();
    });

    it('displays an alert message', () => {
      expect(findAlert().exists()).toBe(true);
    });
  });

  describe('when there are no agentEvents', () => {
    beforeEach(async () => {
      createWrapper({ queryResponse: jest.fn().mockResolvedValue(mockEmptyResponse) });
      await waitForPromises();
    });

    it('displays an empty state with the correct illustration', () => {
      expect(findEmptyState().exists()).toBe(true);
      expect(findEmptyState().props('svgPath')).toBe(activityEmptyStateImage);
    });
  });

  describe('when the agentEvents are present', () => {
    const length = mockResponse.data?.project?.clusterAgent?.activityEvents?.nodes?.length;

    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    it('renders an activity-history-item components for every event', () => {
      expect(findAllActivityHistoryItems()).toHaveLength(length);
    });

    it.each`
      recordedAt                | date              | lineNumber
      ${'2021-12-03T01:06:56Z'} | ${'Today'}        | ${0}
      ${'2021-12-02T19:26:56Z'} | ${'Yesterday'}    | ${1}
      ${'2021-11-22T19:26:56Z'} | ${'Nov 22, 2021'} | ${2}
    `('renders correct titles for different days', ({ date, lineNumber }) => {
      expect(findSectionTitle(lineNumber).text()).toBe(date);
    });
  });
});
