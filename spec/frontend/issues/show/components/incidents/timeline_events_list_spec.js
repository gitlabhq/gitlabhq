import timezoneMock from 'timezone-mock';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import IncidentTimelineEventList from '~/issues/show/components/incidents/timeline_events_list.vue';
import IncidentTimelineEventItem from '~/issues/show/components/incidents/timeline_events_item.vue';
import EditTimelineEvent from '~/issues/show/components/incidents/edit_timeline_event.vue';
import { describeSkipVue3, SkipReason } from 'helpers/vue3_conditional';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import deleteTimelineEventMutation from '~/issues/show/components/incidents/graphql/queries/delete_timeline_event.mutation.graphql';
import editTimelineEventMutation from '~/issues/show/components/incidents/graphql/queries/edit_timeline_event.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useFakeDate } from 'helpers/fake_date';
import { createAlert } from '~/alert';
import {
  mockEvents,
  timelineEventsDeleteEventResponse,
  timelineEventsDeleteEventError,
  timelineEventsEditEventResponse,
  timelineEventsEditEventError,
  fakeDate,
  fakeEventData,
  fakeEventSaveData,
  mockInputData,
} from './mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');
jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');

const mockConfirmAction = ({ confirmed }) => {
  confirmAction.mockResolvedValueOnce(confirmed);
};

const skipReason = new SkipReason({
  name: 'IncidentTimelineEventList',
  reason: 'Caught error after test environment was torn down',
  issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/478771',
});

describeSkipVue3(skipReason, () => {
  useFakeDate(fakeDate);
  let wrapper;
  const deleteResponseSpy = jest.fn().mockResolvedValue(timelineEventsDeleteEventResponse);
  const editResponseSpy = jest.fn().mockResolvedValue(timelineEventsEditEventResponse);

  const requestHandlers = [
    [deleteTimelineEventMutation, deleteResponseSpy],
    [editTimelineEventMutation, editResponseSpy],
  ];
  const apolloProvider = createMockApollo(requestHandlers);

  const mountComponent = () => {
    wrapper = mountExtended(IncidentTimelineEventList, {
      propsData: {
        timelineEvents: mockEvents,
      },
      provide: {
        fullPath: 'group/project',
        issuableId: '1',
        canUpdateTimelineEvent: true,
      },
      apolloProvider,
    });
  };

  const findTimelineEventGroups = () => wrapper.findAllByTestId('timeline-group');
  const findItems = (base = wrapper) => base.findAllComponents(IncidentTimelineEventItem);
  const findFirstTimelineEventGroup = () => findTimelineEventGroups().at(0);
  const findSecondTimelineEventGroup = () => findTimelineEventGroups().at(1);
  const findDates = () => wrapper.findAllByTestId('event-date');
  const clickFirstDeleteButton = async () => {
    findItems().at(0).vm.$emit('delete', { fakeEventData });
    await waitForPromises();
  };

  const clickFirstEditButton = async () => {
    findItems().at(0).vm.$emit('edit');
    await waitForPromises();
  };
  beforeEach(() => {
    mountComponent();
  });

  describe('template', () => {
    it('groups items correctly', () => {
      expect(findTimelineEventGroups()).toHaveLength(2);

      expect(findItems(findFirstTimelineEventGroup())).toHaveLength(1);
      expect(findItems(findSecondTimelineEventGroup())).toHaveLength(2);
    });

    it('sets the event props correctly', () => {
      expect(findItems().at(1).props('occurredAt')).toBe(mockEvents[1].occurredAt);
      expect(findItems().at(1).props('action')).toBe(mockEvents[1].action);
      expect(findItems().at(1).props('noteHtml')).toBe(mockEvents[1].noteHtml);
      expect(findItems().at(1).props('eventTags')).toBe(mockEvents[1].timelineEventTags.nodes);
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

        expect(deleteResponseSpy).toHaveBeenCalledWith(expectedVars);
      });

      it('should show an error when delete returns an error', async () => {
        const expectedError = {
          message: 'Error deleting incident timeline event: Item does not exist',
        };

        deleteResponseSpy.mockResolvedValue(timelineEventsDeleteEventError);

        await clickFirstDeleteButton();

        expect(createAlert).toHaveBeenCalledWith(expectedError);
      });

      it('should show an error when delete fails', async () => {
        const expectedAlertArgs = {
          captureError: true,
          error: new Error(),
          message: 'Something went wrong while deleting the incident timeline event.',
        };
        deleteResponseSpy.mockRejectedValueOnce();

        await clickFirstDeleteButton();

        expect(createAlert).toHaveBeenCalledWith(expectedAlertArgs);
      });
    });
  });

  describe('Edit Functionality', () => {
    beforeEach(() => {
      mountComponent();
      clickFirstEditButton();
    });

    const findEditEvent = () => wrapper.findComponent(EditTimelineEvent);
    const mockHandleSaveEventData = { ...fakeEventData, ...mockInputData };

    describe('editTimelineEvent', () => {
      it('should call the mutation with the right variables', async () => {
        await findEditEvent().vm.$emit('handle-save-edit', mockHandleSaveEventData);
        await waitForPromises();

        expect(editResponseSpy).toHaveBeenCalledWith({
          input: fakeEventSaveData,
        });
      });

      it('should close the form on successful addition', async () => {
        await findEditEvent().vm.$emit('handle-save-edit', fakeEventSaveData);
        await waitForPromises();

        expect(findEditEvent().exists()).toBe(false);
      });

      it('should close the form on cancel', async () => {
        await findEditEvent().vm.$emit('hide-edit');
        await waitForPromises();

        expect(findEditEvent().exists()).toBe(false);
      });
    });

    describe('error handling', () => {
      it('should show an error when submission returns an error', async () => {
        const expectedAlertArgs = {
          message: `Error updating incident timeline event: ${timelineEventsEditEventError.data.timelineEventUpdate.errors[0]}`,
        };
        editResponseSpy.mockResolvedValueOnce(timelineEventsEditEventError);

        await findEditEvent().vm.$emit('handle-save-edit', fakeEventSaveData);
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith(expectedAlertArgs);
      });

      it('should show an error when submission fails', async () => {
        const expectedAlertArgs = {
          captureError: true,
          error: new Error(),
          message: 'Something went wrong while updating the incident timeline event.',
        };
        editResponseSpy.mockRejectedValueOnce();

        await findEditEvent().vm.$emit('handle-save-edit', fakeEventSaveData);
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith(expectedAlertArgs);
      });

      it('should keep the form open on failed addition', async () => {
        editResponseSpy.mockResolvedValueOnce(timelineEventsEditEventError);

        await findEditEvent().vm.$emit('handle-save-edit', fakeEventSaveData);
        await waitForPromises();

        expect(findEditEvent().exists()).toBe(true);
      });
    });
  });
});
