import { shallowMount } from '@vue/test-utils';
import TodoItemTimestamp from '~/todos/components/todo_item_timestamp.vue';
import TodoSnoozedTimestamp from '~/todos/components/todo_snoozed_timestamp.vue';
import { useFakeDate } from 'helpers/fake_date';
import { MR_REVIEW_REQUEST_TODO } from '../mock_data';

describe('TodoItemTimestamp', () => {
  let wrapper;

  const mockCurrentTime = new Date('2024-12-18T13:24:00');
  const mockForAnHour = '2024-12-18T14:24:00';
  const mockYesterday = '2024-12-17T08:00:00';

  useFakeDate(mockCurrentTime);

  const findTodoSnoozedTimestamp = () => wrapper.findComponent(TodoSnoozedTimestamp);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(TodoItemTimestamp, {
      propsData: {
        todo: {
          ...MR_REVIEW_REQUEST_TODO,
        },
        ...props,
      },
    });
  };

  describe('snoozed to-do items', () => {
    it('does not render the TodoSnoozedTimestamp component when the item is not snoozed', () => {
      createComponent({ isSnoozed: false });

      expect(findTodoSnoozedTimestamp().exists()).toBe(false);
    });

    it('renders the TodoSnoozedTimestamp component when the item is snoozed until a future date', () => {
      createComponent({
        todo: {
          ...MR_REVIEW_REQUEST_TODO,
          snoozedUntil: mockForAnHour,
        },
        isSnoozed: true,
      });

      const component = findTodoSnoozedTimestamp();
      expect(component.exists()).toBe(true);
      expect(component.props('snoozedUntil')).toBe(mockForAnHour);
      expect(component.props('hasReachedSnoozeTimestamp')).toBe(false);
    });

    it('renders the TodoSnoozedTimestamp component when the item has reached its snooze time', () => {
      createComponent({
        todo: {
          ...MR_REVIEW_REQUEST_TODO,
          snoozedUntil: mockYesterday,
        },
        isSnoozed: false,
      });

      const component = findTodoSnoozedTimestamp();
      expect(component.exists()).toBe(true);
      expect(component.props('snoozedUntil')).toBe(mockYesterday);
      expect(component.props('hasReachedSnoozeTimestamp')).toBe(true);
    });
  });
});
