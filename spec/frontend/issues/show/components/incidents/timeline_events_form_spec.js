import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { GlDatepicker, GlCollapsibleListbox } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import TimelineEventsForm from '~/issues/show/components/incidents/timeline_events_form.vue';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import {
  timelineFormI18n,
  TIMELINE_EVENT_TAGS,
  timelineEventTagsI18n,
} from '~/issues/show/components/incidents/constants';
import { createAlert } from '~/alert';
import { useFakeDate } from 'helpers/fake_date';

Vue.use(VueApollo);

jest.mock('~/alert');

const fakeDate = '2020-07-08T00:00:00.000Z';

const mockInputDate = new Date('2021-08-12');

const mockTags = TIMELINE_EVENT_TAGS;

describe('Timeline events form', () => {
  // July 8 2020
  useFakeDate(fakeDate);
  let wrapper;

  const mountComponent = ({ mountMethod = mountExtended } = {}, props = {}, glFeatures = {}) => {
    wrapper = mountMethod(TimelineEventsForm, {
      provide: {
        glFeatures,
      },
      propsData: {
        showSaveAndAdd: true,
        isEventProcessed: false,
        ...props,
        tags: mockTags,
      },
      stubs: {
        GlButton: true,
      },
    });
  };

  beforeEach(() => {
    mountComponent();
  });

  afterEach(() => {
    createAlert.mockReset();
  });

  const findMarkdownField = () => wrapper.findComponent(MarkdownField);
  const findSubmitButton = () => wrapper.findByTestId('save-button');
  const findSubmitAndAddButton = () => wrapper.findByTestId('save-and-add-button');
  const findCancelButton = () => wrapper.findByTestId('cancel-button');
  const findDeleteButton = () => wrapper.findByTestId('delete-button');
  const findDatePicker = () => wrapper.findComponent(GlDatepicker);
  const findHourInput = () => wrapper.findByTestId('input-hours');
  const findMinuteInput = () => wrapper.findByTestId('input-minutes');
  const findTagsListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findTextarea = () => wrapper.findByTestId('input-note');
  const findTextareaValue = () => findTextarea().element.value;
  const findCountNumeric = (count) => wrapper.findByText(count);
  const findCountVerbose = (count) => wrapper.findByText(`${count} characters remaining`);
  const findCountHint = () => wrapper.findByText(timelineFormI18n.hint);

  const setDatetime = () => {
    findDatePicker().vm.$emit('input', mockInputDate);
    findHourInput().setValue(5);
    findMinuteInput().setValue(45);
  };
  const selectTags = async (tags) => {
    findTagsListbox().vm.$emit(
      'select',
      tags.map((x) => x.value),
    );
    await nextTick();
  };
  const selectOneTag = () => selectTags([mockTags[0]]);
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
  const deleteForm = () => {
    findDeleteButton().vm.$emit('click');
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

  describe('Event Tags', () => {
    describe('event tags listbox', () => {
      it('should render option list from provided array', () => {
        expect(findTagsListbox().props('items')).toEqual(mockTags);
      });

      it('should allow to choose multiple tags', async () => {
        await selectTags(mockTags);

        expect(findTagsListbox().props('selected')).toEqual(mockTags.map((x) => x.value));
      });

      it('should show default option, when none is chosen', () => {
        expect(findTagsListbox().props('toggleText')).toBe(timelineFormI18n.selectTags);
      });

      it('should show the tag, when one is selected', async () => {
        await selectOneTag();

        expect(findTagsListbox().props('toggleText')).toBe(timelineEventTagsI18n.startTime);
      });

      it('should show the number of selected tags, when more than one is selected', async () => {
        await selectTags(mockTags);

        expect(findTagsListbox().props('toggleText')).toBe(`${mockTags.length} tags`);
      });

      it('should be cleared when clear is triggered', async () => {
        await selectTags(mockTags);

        // This component expects the parent to call `clear`, so this is the only way to trigger this
        wrapper.vm.clear();
        await nextTick();

        expect(findTagsListbox().props('toggleText')).toBe(timelineFormI18n.selectTags);
        expect(findTagsListbox().props('selected')).toEqual([]);
      });

      it('should populate incident note with tags if a note was empty', async () => {
        await selectTags(mockTags);

        expect(findTextareaValue()).toBe(
          `${timelineFormI18n.areaDefaultMessage} ${mockTags
            .map((x) => x.value.toLowerCase())
            .join(', ')}`,
        );
      });

      it('should populate incident note with tag but allow to customise it', async () => {
        await selectOneTag();

        await findTextarea().setValue('my customised event note');

        await nextTick();

        expect(findTextareaValue()).toBe('my customised event note');
      });

      it('should not populate incident note with tag if it had a note', async () => {
        await findTextarea().setValue('hello');
        await selectOneTag();

        expect(findTextareaValue()).toBe('hello');
      });
    });

    describe('form button behaviour', () => {
      it('should enable the save buttons when event does not include tags', async () => {
        await findTextarea().setValue('hello');

        expect(findTagsListbox().props('toggleText')).toBe(timelineFormI18n.selectTags);
        expect(findSubmitButton().props('disabled')).toBe(false);
        expect(findSubmitAndAddButton().props('disabled')).toBe(false);
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
        expect(findTagsListbox().props('toggleText')).toBe(timelineFormI18n.selectTags);
      });
    });
  });

  describe('form button behaviour', () => {
    it('should save event on submit', async () => {
      await submitForm();

      expect(wrapper.emitted()).toEqual({
        'save-event': [[{ note: '', occurredAt: fakeDate, timelineEventTags: [] }, false]],
      });
    });

    it('should save event on "submit and add another"', async () => {
      await submitFormAndAddAnother();
      expect(wrapper.emitted()).toEqual({
        'save-event': [[{ note: '', occurredAt: fakeDate, timelineEventTags: [] }, true]],
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

    it('should disable the save buttons when event content does not exist', () => {
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

  describe('Delete button', () => {
    it('does not show the delete button if isEditing prop is false', () => {
      mountComponent({ mountMethod: mountExtended }, { isEditing: false });

      expect(findDeleteButton().exists()).toBe(false);
    });

    it('shows the delete button if isEditing prop is true', () => {
      mountComponent({ mountMethod: mountExtended }, { isEditing: true });

      expect(findDeleteButton().exists()).toBe(true);
    });

    it('disables the delete button if isEventProcessed prop is true', () => {
      mountComponent({ mountMethod: mountExtended }, { isEditing: true, isEventProcessed: true });

      expect(findDeleteButton().props('disabled')).toBe(true);
    });

    it('does not disable the delete button if isEventProcessed prop is false', () => {
      mountComponent({ mountMethod: mountExtended }, { isEditing: true, isEventProcessed: false });

      expect(findDeleteButton().props('disabled')).toBe(false);
    });

    it('emits delete event on click', () => {
      mountComponent({ mountMethod: mountExtended }, { isEditing: true, isEventProcessed: true });

      deleteForm();

      expect(wrapper.emitted('delete')).toEqual([[]]);
    });
  });
});
