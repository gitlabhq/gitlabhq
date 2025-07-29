import { shallowMount } from '@vue/test-utils';
import { GlFormCheckbox, GlLink } from '@gitlab/ui';
import TodoItem from '~/todos/components/todo_item.vue';
import TodoItemBody from '~/todos/components/todo_item_body.vue';
import TodoItemTimestamp from '~/todos/components/todo_item_timestamp.vue';
import TodoItemActions from '~/todos/components/todo_item_actions.vue';
import { useFakeDate } from 'helpers/fake_date';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { MR_REVIEW_REQUEST_TODO } from '../mock_data';

describe('TodoItem', () => {
  let wrapper;

  const mockCurrentTime = new Date('2024-12-18T13:24:00');
  const mockUntilTomorrow = '2024-12-19T08:00:00';
  const mockYesterday = '2024-12-17T08:00:00';

  useFakeDate(mockCurrentTime);

  const findTodoItemTimestamp = () => wrapper.findComponent(TodoItemTimestamp);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(TodoItem, {
      propsData: {
        currentUserId: '1',
        todo: {
          ...MR_REVIEW_REQUEST_TODO,
        },
        ...props,
      },
      provide: {
        currentTab: 0,
      },
    });
  };

  it('renders the component', () => {
    createComponent();
    expect(wrapper.exists()).toBe(true);
  });

  it('renders TodoItemBody component', () => {
    createComponent();
    expect(wrapper.findComponent(TodoItemBody).exists()).toBe(true);
  });

  it('renders TodoItemTimestamp component', () => {
    createComponent();
    expect(findTodoItemTimestamp().exists()).toBe(true);
  });

  it('renders TodoItemActions component', () => {
    createComponent();
    expect(wrapper.findComponent(TodoItemActions).exists()).toBe(true);
  });

  describe('should track', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    it('on click', () => {
      createComponent();
      const { trackEventSpy, triggerEvent } = bindInternalEventDocument(wrapper.element);

      triggerEvent(wrapper.findComponent(GlLink).element);
      expect(trackEventSpy).toHaveBeenCalledWith('follow_todo_link', {
        label: 'MERGEREQUEST',
        property: 'review_requested',
      });
    });
  });

  it('emits change event when TodoItemActions emits change', async () => {
    createComponent();
    const todoItemActions = wrapper.findComponent(TodoItemActions);
    await todoItemActions.vm.$emit('change');
    expect(wrapper.emitted('change')).toHaveLength(1);
  });

  describe('multi-select checkbox', () => {
    describe('with `selectable` prop `false` (default)', () => {
      it('renders a checkbox', () => {
        createComponent();
        expect(wrapper.findComponent(GlFormCheckbox).exists()).toBe(false);
      });
    });

    describe('with `selectable` prop `true`', () => {
      it('renders a checkbox', () => {
        createComponent({ selectable: true });
        expect(wrapper.findComponent(GlFormCheckbox).exists()).toBe(true);
      });

      it('emits select-change event when checkbox changes', async () => {
        createComponent({ selectable: true });
        const checkbox = wrapper.findComponent(GlFormCheckbox);
        await checkbox.vm.$emit('change', true);

        expect(wrapper.emitted('select-change')[0]).toEqual([MR_REVIEW_REQUEST_TODO.id, true]);
      });
    });
  });

  describe('isSnoozed status', () => {
    it('sets `isSnoozed` to `true` if the todo has a snoozed date set in the future', () => {
      createComponent({ todo: { ...MR_REVIEW_REQUEST_TODO, snoozedUntil: mockUntilTomorrow } });

      expect(wrapper.findComponent(TodoItemActions).props('isSnoozed')).toBe(true);
    });

    it('sets `isSnoozed` to `false` if the todo has no snoozed date', () => {
      createComponent();

      expect(wrapper.findComponent(TodoItemActions).props('isSnoozed')).toBe(false);
    });

    it('sets `isSnoozed` to `false` if the todo has a snoozed date set in the past', () => {
      createComponent({ todo: { ...MR_REVIEW_REQUEST_TODO, snoozedUntil: mockYesterday } });

      expect(wrapper.findComponent(TodoItemActions).props('isSnoozed')).toBe(false);
    });
  });
});
