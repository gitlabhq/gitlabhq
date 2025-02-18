import { shallowMount } from '@vue/test-utils';
import { GlIcon, GlFormCheckbox } from '@gitlab/ui';
import TodoItem from '~/todos/components/todo_item.vue';
import TodoItemTitle from '~/todos/components/todo_item_title.vue';
import TodoItemTitleHiddenBySaml from '~/todos/components/todo_item_title_hidden_by_saml.vue';
import TodoItemBody from '~/todos/components/todo_item_body.vue';
import TodoItemTimestamp from '~/todos/components/todo_item_timestamp.vue';
import TodoItemActions from '~/todos/components/todo_item_actions.vue';
import { TODO_STATE_DONE, TODO_STATE_PENDING } from '~/todos/constants';
import { useFakeDate } from 'helpers/fake_date';
import { SAML_HIDDEN_TODO, MR_REVIEW_REQUEST_TODO } from '../mock_data';

describe('TodoItem', () => {
  let wrapper;

  const mockCurrentTime = new Date('2024-12-18T13:24:00');
  const mockForAnHour = new Date('2024-12-18T14:24:00');
  const mockUntilLaterToday = new Date('2024-12-18T17:24:00');
  const mockUntilTomorrow = new Date('2024-12-19T08:00:00');
  const mockUntilNextWeek = new Date('2024-12-25T08:00:00');
  const mockYesterday = new Date('2024-12-17T08:00:00');

  useFakeDate(mockCurrentTime);

  const findTodoItemTimestamp = () => wrapper.findComponent(TodoItemTimestamp);

  const createComponent = (props = {}, todosBulkActions = true) => {
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
        glFeatures: { todosBulkActions },
      },
    });
  };

  it('renders the component', () => {
    createComponent();
    expect(wrapper.exists()).toBe(true);
  });

  it('renders TodoItemTitle component for normal todos', () => {
    createComponent();
    expect(wrapper.findComponent(TodoItemTitle).exists()).toBe(true);
  });

  it('renders TodoItemTitleHiddenBySaml component for hidden todos', () => {
    createComponent({ todo: SAML_HIDDEN_TODO });
    expect(wrapper.findComponent(TodoItemTitleHiddenBySaml).exists()).toBe(true);
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

  describe('state based style', () => {
    it('applies background when todo is done', () => {
      createComponent({ todo: { state: TODO_STATE_DONE } });
      expect(wrapper.classes()).toContain('gl-bg-subtle');
    });

    it('applies no background when todo is pending', () => {
      createComponent({ todo: { state: TODO_STATE_PENDING } });
      expect(wrapper.classes()).not.toContain('gl-bg-subtle');
    });
  });

  describe('computed properties', () => {
    it('isDone returns true when todo state is done', () => {
      createComponent({ todo: { state: TODO_STATE_DONE } });
      expect(wrapper.vm.isDone).toBe(true);
    });
  });

  it('emits change event when TodoItemActions emits change', async () => {
    createComponent();
    const todoItemActions = wrapper.findComponent(TodoItemActions);
    await todoItemActions.vm.$emit('change');
    expect(wrapper.emitted('change')).toHaveLength(1);
  });

  describe('multi-select checkbox', () => {
    it('renders a checkbox', () => {
      createComponent();
      expect(wrapper.findComponent(GlFormCheckbox).exists()).toBe(true);
    });

    it('emits select-change event when checkbox changes', async () => {
      createComponent();
      const checkbox = wrapper.findComponent(GlFormCheckbox);
      await checkbox.vm.$emit('change', true);

      expect(wrapper.emitted('select-change')[0]).toEqual([MR_REVIEW_REQUEST_TODO.id, true]);
    });

    it('does not render a checkbox with feature flag disabled', () => {
      createComponent({}, false);
      expect(wrapper.findComponent(GlFormCheckbox).exists()).toBe(false);
    });
  });

  describe('snoozed to-do items', () => {
    it.each`
      snoozedUntil           | expectedLabel
      ${mockForAnHour}       | ${'Snoozed until 2:24 PM'}
      ${mockUntilLaterToday} | ${'Snoozed until 5:24 PM'}
      ${mockUntilTomorrow}   | ${'Snoozed until tomorrow, 8:00 AM'}
      ${mockUntilNextWeek}   | ${'Snoozed until Dec 25, 2024'}
    `(
      'renders "$expectedLabel" when the item is snoozed until a future date ($snoozedUntil)',
      ({ snoozedUntil, expectedLabel }) => {
        createComponent({
          todo: {
            ...MR_REVIEW_REQUEST_TODO,
            snoozedUntil,
          },
        });

        expect(findTodoItemTimestamp().exists()).toBe(false);
        expect(wrapper.text()).toBe(expectedLabel);
      },
    );

    it('renders the creation date when the item has reached its snooze time', () => {
      createComponent({
        todo: {
          ...MR_REVIEW_REQUEST_TODO,
          snoozedUntil: mockYesterday,
        },
      });

      expect(findTodoItemTimestamp().exists()).toBe(false);
      expect(wrapper.text()).toBe('First sent 4 months ago');

      const icon = wrapper.findComponent(GlIcon);
      expect(icon.exists()).toBe(true);
      expect(icon.props('name')).toBe('clock');
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
