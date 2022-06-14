import { GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import TimelineEventsTab from '~/issues/show/components/incidents/timeline_events_tab.vue';
import IncidentTimelineEventsList from '~/issues/show/components/incidents/timeline_events_list.vue';
import timelineEventsQuery from '~/issues/show/components/incidents/graphql/queries/get_timeline_events.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createAlert } from '~/flash';
import { timelineEventsQueryListResponse, timelineEventsQueryEmptyResponse } from './mock_data';

Vue.use(VueApollo);

jest.mock('~/flash');

const graphQLError = new Error('GraphQL error');
const listResponse = jest.fn().mockResolvedValue(timelineEventsQueryListResponse);
const emptyResponse = jest.fn().mockResolvedValue(timelineEventsQueryEmptyResponse);
const errorResponse = jest.fn().mockRejectedValue(graphQLError);

function createMockApolloProvider(response = listResponse) {
  const requestHandlers = [[timelineEventsQuery, response]];
  return createMockApollo(requestHandlers);
}

describe('TimelineEventsTab', () => {
  let wrapper;

  const mountComponent = (options = {}) => {
    const { mockApollo, mountMethod = shallowMountExtended } = options;

    wrapper = mountMethod(TimelineEventsTab, {
      provide: {
        fullPath: 'group/project',
        issuableId: '1',
      },
      apolloProvider: mockApollo,
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  const findLoadingSpinner = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findTimelineEventsList = () => wrapper.findComponent(IncidentTimelineEventsList);

  describe('Timeline events tab', () => {
    describe('empty state', () => {
      let mockApollo;

      it('should show an empty list', async () => {
        mockApollo = createMockApolloProvider(emptyResponse);
        mountComponent({ mockApollo });
        await waitForPromises();

        expect(findEmptyState().exists()).toBe(true);
      });
    });

    describe('error state', () => {
      let mockApollo;

      it('should show an error state', async () => {
        mockApollo = createMockApolloProvider(errorResponse);
        mountComponent({ mockApollo });
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          captureError: true,
          error: graphQLError,
          message: 'Something went wrong while fetching incident timeline events.',
        });
      });
    });
  });

  describe('timelineEventsQuery', () => {
    let mockApollo;

    beforeEach(() => {
      mockApollo = createMockApolloProvider();
      mountComponent({ mockApollo });
    });

    it('should request data', () => {
      expect(listResponse).toHaveBeenCalled();
    });

    it('should show the loading state', () => {
      expect(findEmptyState().exists()).toBe(false);
      expect(findLoadingSpinner().exists()).toBe(true);
    });

    it('should render the list', async () => {
      await waitForPromises();
      expect(findEmptyState().exists()).toBe(false);
      expect(findTimelineEventsList().props('timelineEvents')).toHaveLength(3);
    });
  });
});
