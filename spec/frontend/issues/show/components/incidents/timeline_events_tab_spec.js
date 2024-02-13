import { GlLoadingIcon } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import TimelineEventsTab from '~/issues/show/components/incidents/timeline_events_tab.vue';
import IncidentTimelineEventsList from '~/issues/show/components/incidents/timeline_events_list.vue';
import CreateTimelineEvent from '~/issues/show/components/incidents/create_timeline_event.vue';
import timelineEventsQuery from '~/issues/show/components/incidents/graphql/queries/get_timeline_events.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createAlert } from '~/alert';
import { timelineTabI18n } from '~/issues/show/components/incidents/constants';
import { timelineEventsQueryListResponse, timelineEventsQueryEmptyResponse } from './mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

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
    const { mockApollo, mountMethod = shallowMountExtended, stubs, provide } = options;

    wrapper = mountMethod(TimelineEventsTab, {
      provide: {
        fullPath: 'group/project',
        issuableId: '1',
        canUpdateTimelineEvent: true,
        ...provide,
      },
      apolloProvider: mockApollo,
      stubs,
    });
  };

  const findLoadingSpinner = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.find('p');
  const findTimelineEventsList = () => wrapper.findComponent(IncidentTimelineEventsList);
  const findCreateTimelineEvent = () => wrapper.findComponent(CreateTimelineEvent);
  const findAddEventButton = () => wrapper.findByText(timelineTabI18n.addEventButton);

  describe('Timeline events tab', () => {
    describe('empty state', () => {
      let mockApollo;

      it('should show an empty list', async () => {
        mockApollo = createMockApolloProvider(emptyResponse);
        mountComponent({ mockApollo });
        await waitForPromises();

        expect(findEmptyState().exists()).toBe(true);
        expect(findEmptyState().text()).toBe('No timeline items have been added yet.');
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

    const setup = () => {
      mockApollo = createMockApolloProvider();
      mountComponent({ mockApollo });
    };

    it('should request data', () => {
      setup();

      expect(listResponse).toHaveBeenCalled();
    });

    it('should show the loading state', () => {
      setup();

      expect(findEmptyState().exists()).toBe(false);
      expect(findLoadingSpinner().exists()).toBe(true);
    });

    it('should render the list', async () => {
      setup();
      await waitForPromises();

      expect(findEmptyState().exists()).toBe(false);
      expect(findTimelineEventsList().props('timelineEvents')).toHaveLength(
        timelineEventsQueryListResponse.data.project.incidentManagementTimelineEvents.nodes.length,
      );
    });
  });

  describe('add new event form', () => {
    beforeEach(async () => {
      mountComponent({
        mockApollo: createMockApolloProvider(emptyResponse),
        mountMethod: mountExtended,
        stubs: {
          'incident-timeline-events-list': true,
          'gl-tab': true,
        },
      });
      await waitForPromises();
    });

    it('should show a button when user can update', () => {
      expect(findAddEventButton().exists()).toBe(true);
    });

    it('should not show a button when user cannot update', () => {
      mountComponent({
        mockApollo: createMockApolloProvider(emptyResponse),
        provide: { canUpdateTimelineEvent: false },
      });

      expect(findAddEventButton().exists()).toBe(false);
    });

    it('should not show a form by default', () => {
      expect(findCreateTimelineEvent().exists()).toBe(false);
    });

    it('should show a form when button is clicked', async () => {
      await findAddEventButton().trigger('click');

      expect(findCreateTimelineEvent().exists()).toBe(true);
    });

    it('should hide the form when the hide event is emitted', async () => {
      // open the form
      await findAddEventButton().trigger('click');

      await findCreateTimelineEvent().vm.$emit('hide-new-timeline-events-form');

      expect(findCreateTimelineEvent().exists()).toBe(false);
    });
  });
});
