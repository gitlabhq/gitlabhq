import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { GlDatepicker } from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import TimelineEventsForm from '~/issues/show/components/incidents/timeline_events_form.vue';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import { timelineFormI18n } from '~/issues/show/components/incidents/constants';
import { createAlert } from '~/flash';
import { useFakeDate } from 'helpers/fake_date';

Vue.use(VueApollo);

jest.mock('~/flash');

const fakeDate = '2020-07-08T00:00:00.000Z';

const mockInputDate = new Date('2021-08-12');

describe('Timeline events form', () => {
  // July 8 2020
  useFakeDate(fakeDate);
  let wrapper;

  const mountComponent = ({ mountMethod = shallowMountExtended }) => {
    wrapper = mountMethod(TimelineEventsForm, {
      propsData: {
        showSaveAndAdd: true,
        isEventProcessed: false,
      },
    });
  };

  afterEach(() => {
    createAlert.mockReset();
    wrapper.destroy();
  });

  const findMarkdownField = () => wrapper.findComponent(MarkdownField);
  const findSubmitButton = () => wrapper.findByText(timelineFormI18n.save);
  const findSubmitAndAddButton = () => wrapper.findByText(timelineFormI18n.saveAndAdd);
  const findCancelButton = () => wrapper.findByText(timelineFormI18n.cancel);
  const findDatePicker = () => wrapper.findComponent(GlDatepicker);
  const findHourInput = () => wrapper.findByTestId('input-hours');
  const findMinuteInput = () => wrapper.findByTestId('input-minutes');
  const setDatetime = () => {
    findDatePicker().vm.$emit('input', mockInputDate);
    findHourInput().setValue(5);
    findMinuteInput().setValue(45);
  };

  const submitForm = async () => {
    findSubmitButton().trigger('click');
    await waitForPromises();
  };
  const submitFormAndAddAnother = async () => {
    findSubmitAndAddButton().trigger('click');
    await waitForPromises();
  };
  const cancelForm = async () => {
    findCancelButton().trigger('click');
    await waitForPromises();
  };

  it('renders markdown-field component with correct list of toolbar items', () => {
    mountComponent({ mountMethod: mountExtended });

    expect(findMarkdownField().props('restrictedToolBarItems')).toEqual([
      'quote',
      'strikethrough',
      'bullet-list',
      'numbered-list',
      'task-list',
      'collapsible-section',
      'table',
      'attach-file',
      'full-screen',
    ]);
  });

  describe('form button behaviour', () => {
    beforeEach(() => {
      mountComponent({ mountMethod: mountExtended });
    });

    it('should save event on submit', async () => {
      await submitForm();

      expect(wrapper.emitted()).toEqual({
        'save-event': [[{ note: '', occurredAt: fakeDate }, false]],
      });
    });

    it('should save event on "submit and add another"', async () => {
      await submitFormAndAddAnother();
      expect(wrapper.emitted()).toEqual({
        'save-event': [[{ note: '', occurredAt: fakeDate }, true]],
      });
    });

    it('should emit cancel on cancel', async () => {
      await cancelForm();
      expect(wrapper.emitted()).toEqual({ cancel: [[]] });
    });

    it('should clear the form', async () => {
      setDatetime();
      await nextTick();

      expect(findDatePicker().props('value')).toBe(mockInputDate);
      expect(findHourInput().element.value).toBe('5');
      expect(findMinuteInput().element.value).toBe('45');

      wrapper.vm.clear();
      await nextTick();

      expect(findDatePicker().props('value')).toStrictEqual(new Date(fakeDate));
      expect(findHourInput().element.value).toBe('0');
      expect(findMinuteInput().element.value).toBe('0');
    });
  });
});
