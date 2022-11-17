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

  const mountComponent = ({ mountMethod = shallowMountExtended } = {}) => {
    wrapper = mountMethod(TimelineEventsForm, {
      propsData: {
        showSaveAndAdd: true,
        isEventProcessed: false,
      },
      stubs: {
        GlButton: true,
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
  const findTextarea = () => wrapper.findByTestId('input-note');
  const findCountNumeric = (count) => wrapper.findByText(count);
  const findCountVerbose = (count) => wrapper.findByText(`${count} characters remaining`);
  const findCountHint = () => wrapper.findByText(timelineFormI18n.hint);

  const submitForm = async () => {
    findSubmitButton().vm.$emit('click');
    await waitForPromises();
  };
  const submitFormAndAddAnother = async () => {
    findSubmitAndAddButton().vm.$emit('click');
    await waitForPromises();
  };
  const cancelForm = async () => {
    findCancelButton().vm.$emit('click');
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

    it('should disable the save buttons when event content does not exist', async () => {
      expect(findSubmitButton().props('disabled')).toBe(true);
      expect(findSubmitAndAddButton().props('disabled')).toBe(true);
    });

    it('should enable the save buttons when event content exists', async () => {
      await findTextarea().setValue('hello');

      expect(findSubmitButton().props('disabled')).toBe(false);
      expect(findSubmitAndAddButton().props('disabled')).toBe(false);
    });
  });

  describe('form character limit', () => {
    beforeEach(() => {
      mountComponent({ mountMethod: mountExtended });
    });

    it('sets a character limit hint', () => {
      expect(findCountHint().exists()).toBe(true);
    });

    it('sets a character limit when text is entered', async () => {
      await findTextarea().setValue('hello');

      expect(findCountNumeric('275').text()).toBe('275');
      expect(findCountVerbose('275').text()).toBe('275 characters remaining');
    });

    it('prevents form submission when text is beyond maximum length', async () => {
      // 281 characters long
      const longText =
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in volupte';
      await findTextarea().setValue(longText);

      expect(findSubmitButton().props('disabled')).toBe(true);
      expect(findSubmitAndAddButton().props('disabled')).toBe(true);
    });
  });
});
