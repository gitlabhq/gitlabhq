import timezoneMock from 'timezone-mock';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import IncidentTimelineEventList from '~/issues/show/components/incidents/timeline_events_list.vue';
import IncidentTimelineEventItem from '~/issues/show/components/incidents/timeline_events_item.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import deleteTimelineEventMutation from '~/issues/show/components/incidents/graphql/queries/delete_timeline_event.mutation.graphql';
import getTimelineEvents from '~/issues/show/components/incidents/graphql/queries/get_timeline_events.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useFakeDate } from 'helpers/fake_date';
import { createAlert } from '~/flash';
import {
  mockEvents,
  timelineEventsDeleteEventResponse,
  timelineEventsDeleteEventError,
  fakeDate,
  fakeEventData,
  timelineEventsQueryListResponse,
} from './mock_data';

Vue.use(VueApollo);

jest.mock('~/flash');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');

const mockConfirmAction = ({ confirmed }) => {
  confirmAction.mockResolvedValueOnce(confirmed);
};

describe('IncidentTimelineEventList', () => {
  useFakeDate(fakeDate);
  let wrapper;
  const responseSpy = jest.fn().mockResolvedValue(timelineEventsDeleteEventResponse);

  const requestHandlers = [[deleteTimelineEventMutation, responseSpy]];
  const apolloProvider = createMockApollo(requestHandlers);

  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: getTimelineEvents,
    data: timelineEventsQueryListResponse.data,
    variables: {
      fullPath: 'group/project',
      incidentId: 'gid://gitlab/Issue/1',
    },
  });

  const mountComponent = () => {
    wrapper = mountExtended(IncidentTimelineEventList, {
      propsData: {
        timelineEvents: mockEvents,
      },
      provide: {
        fullPath: 'group/project',
        issuableId: '1',
        canUpdate: true,
      },
      apolloProvider,
    });
  };

  const findTimelineEventGroups = () => wrapper.findAllByTestId('timeline-group');
  const findItems = (base = wrapper) => base.findAll(IncidentTimelineEventItem);
  const findFirstTimelineEventGroup = () => findTimelineEventGroups().at(0);
  const findSecondTimelineEventGroup = () => findTimelineEventGroups().at(1);
  const findDates = () => wrapper.findAllByTestId('event-date');
  const clickFirstDeleteButton = async () => {
    findItems().at(0).vm.$emit('delete', { fakeEventData });
    await waitForPromises();
  };

  beforeEach(() => {
    mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    it('groups items correctly', () => {
      expect(findTimelineEventGroups()).toHaveLength(2);

      expect(findItems(findFirstTimelineEventGroup())).toHaveLength(1);
      expect(findItems(findSecondTimelineEventGroup())).toHaveLength(2);
    });

    it('sets the isLastItem prop correctly', () => {
      expect(findItems().at(0).props('isLastItem')).toBe(false);
      expect(findItems().at(1).props('isLastItem')).toBe(false);
      expect(findItems().at(2).props('isLastItem')).toBe(true);
    });

    it('sets the event props correctly', () => {
      expect(findItems().at(1).props('occurredAt')).toBe(mockEvents[1].occurredAt);
      expect(findItems().at(1).props('action')).toBe(mockEvents[1].action);
      expect(findItems().at(1).props('noteHtml')).toBe(mockEvents[1].noteHtml);
    });

    it('formats dates correctly', () => {
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
        await clickFirstDeleteButton();

        expect(responseSpy).toHaveBeenCalledWith(expectedVars);
      });

      it('should show an error when delete returns an error', async () => {
        const expectedError = {
          message: 'Error deleting incident timeline event: Item does not exist',
        };

        responseSpy.mockResolvedValue(timelineEventsDeleteEventError);

        await clickFirstDeleteButton();

        expect(createAlert).toHaveBeenCalledWith(expectedError);
      });

      it('should show an error when delete fails', async () => {
        const expectedAlertArgs = {
          captureError: true,
          error: new Error(),
          message: 'Something went wrong while deleting the incident timeline event.',
        };
        responseSpy.mockRejectedValueOnce();

        await clickFirstDeleteButton();

        expect(createAlert).toHaveBeenCalledWith(expectedAlertArgs);
      });
    });
  });
});
