import timezoneMock from 'timezone-mock';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import IncidentTimelineEventList from '~/issues/show/components/incidents/timeline_events_list.vue';
import IncidentTimelineEventListItem from '~/issues/show/components/incidents/timeline_events_list_item.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import deleteTimelineEventMutation from '~/issues/show/components/incidents/graphql/queries/delete_timeline_event.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createAlert } from '~/flash';
import {
  mockEvents,
  timelineEventsDeleteEventResponse,
  timelineEventsDeleteEventError,
} from './mock_data';

Vue.use(VueApollo);

jest.mock('~/flash');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');

const deleteEventResponse = jest.fn();

function createMockApolloProvider() {
  deleteEventResponse.mockResolvedValue(timelineEventsDeleteEventResponse);
  const requestHandlers = [[deleteTimelineEventMutation, deleteEventResponse]];
  return createMockApollo(requestHandlers);
}

const mockConfirmAction = ({ confirmed }) => {
  confirmAction.mockResolvedValueOnce(confirmed);
};

describe('IncidentTimelineEventList', () => {
  let wrapper;

  const mountComponent = (mockApollo) => {
    const apollo = mockApollo ? { apolloProvider: mockApollo } : {};

    wrapper = shallowMountExtended(IncidentTimelineEventList, {
      provide: {
        fullPath: 'group/project',
        issuableId: '1',
      },
      propsData: {
        timelineEvents: mockEvents,
      },
      ...apollo,
    });
  };

  const findTimelineEventGroups = () => wrapper.findAllByTestId('timeline-group');
  const findItems = (base = wrapper) => base.findAll(IncidentTimelineEventListItem);
  const findFirstTimelineEventGroup = () => findTimelineEventGroups().at(0);
  const findSecondTimelineEventGroup = () => findTimelineEventGroups().at(1);
  const findDates = () => wrapper.findAllByTestId('event-date');
  const clickFirstDeleteButton = async () => {
    findItems()
      .at(0)
      .vm.$emit('delete', { ...mockEvents[0] });
    await waitForPromises();
  };

  afterEach(() => {
    confirmAction.mockReset();
    deleteEventResponse.mockReset();
    wrapper.destroy();
  });

  describe('template', () => {
    it('groups items correctly', () => {
      mountComponent();

      expect(findTimelineEventGroups()).toHaveLength(2);

      expect(findItems(findFirstTimelineEventGroup())).toHaveLength(1);
      expect(findItems(findSecondTimelineEventGroup())).toHaveLength(2);
    });

    it('sets the isLastItem prop correctly', () => {
      mountComponent();

      expect(findItems().at(0).props('isLastItem')).toBe(false);
      expect(findItems().at(1).props('isLastItem')).toBe(false);
      expect(findItems().at(2).props('isLastItem')).toBe(true);
    });

    it('sets the event props correctly', () => {
      mountComponent();

      expect(findItems().at(1).props('occurredAt')).toBe(mockEvents[1].occurredAt);
      expect(findItems().at(1).props('action')).toBe(mockEvents[1].action);
      expect(findItems().at(1).props('noteHtml')).toBe(mockEvents[1].noteHtml);
    });

    it('formats dates correctly', () => {
      mountComponent();

      expect(findDates().at(0).text()).toBe('2022-03-22');
      expect(findDates().at(1).text()).toBe('2022-03-23');
    });

    describe.each`
      timezone
      ${'Europe/London'}
      ${'US/Pacific'}
      ${'Australia/Adelaide'}
    `('when viewing in timezone', ({ timezone }) => {
      describe(timezone, () => {
        beforeEach(() => {
          timezoneMock.register(timezone);

          mountComponent();
        });

        afterEach(() => {
          timezoneMock.unregister();
        });

        it('displays the correct time', () => {
          expect(findDates().at(0).text()).toBe('2022-03-22');
        });
      });
    });

    describe('delete functionality', () => {
      beforeEach(() => {
        mockConfirmAction({ confirmed: true });
      });

      it('should delete when button is clicked', async () => {
        const expectedVars = { input: { id: mockEvents[0].id } };

        mountComponent(createMockApolloProvider());

        await clickFirstDeleteButton();

        expect(deleteEventResponse).toHaveBeenCalledWith(expectedVars);
      });

      it('should show an error when delete returns an error', async () => {
        const expectedError = {
          message: 'Error deleting incident timeline event: Item does not exist',
        };

        mountComponent(createMockApolloProvider());
        deleteEventResponse.mockResolvedValue(timelineEventsDeleteEventError);

        await clickFirstDeleteButton();

        expect(createAlert).toHaveBeenCalledWith(expectedError);
      });

      it('should show an error when delete fails', async () => {
        const expectedAlertArgs = {
          captureError: true,
          error: new Error(),
          message: 'Something went wrong while deleting the incident timeline event.',
        };
        mountComponent(createMockApolloProvider());
        deleteEventResponse.mockRejectedValueOnce();

        await clickFirstDeleteButton();

        expect(createAlert).toHaveBeenCalledWith(expectedAlertArgs);
      });
    });
  });
});
