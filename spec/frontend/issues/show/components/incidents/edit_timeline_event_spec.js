import EditTimelineEvent from '~/issues/show/components/incidents/edit_timeline_event.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import TimelineEventsForm from '~/issues/show/components/incidents/timeline_events_form.vue';

import { mockEvents, fakeEventData, mockInputData } from './mock_data';

describe('Edit Timeline events', () => {
  let wrapper;

  const mountComponent = () => {
    wrapper = mountExtended(EditTimelineEvent, {
      propsData: {
        event: mockEvents[0],
        editTimelineEventActive: false,
      },
    });
  };

  beforeEach(() => {
    mountComponent();
  });

  const findTimelineEventsForm = () => wrapper.findComponent(TimelineEventsForm);

  const mockSaveData = {
    ...fakeEventData,
    ...mockInputData,
    timelineEventTags: ['Start time', 'End time'],
  };

  describe('editTimelineEvent', () => {
    const saveEventEvent = { 'handle-save-edit': [[mockSaveData, false]] };

    it('should call the mutation with the right variables', async () => {
      await findTimelineEventsForm().vm.$emit('save-event', mockSaveData, false);

      expect(wrapper.emitted()).toEqual(saveEventEvent);
    });

    it('should close the form on cancel', async () => {
      const cancelEvent = { 'hide-edit': [[]] };

      await findTimelineEventsForm().vm.$emit('cancel');

      expect(wrapper.emitted()).toEqual(cancelEvent);
    });

    it('should emit the delete event', async () => {
      const deleteEvent = { delete: [[]] };

      await findTimelineEventsForm().vm.$emit('delete');

      expect(wrapper.emitted()).toEqual(deleteEvent);
    });
  });
});
