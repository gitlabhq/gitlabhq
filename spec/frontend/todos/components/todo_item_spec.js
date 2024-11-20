import { shallowMount } from '@vue/test-utils';
import TodoItem from '~/todos/components/todo_item.vue';
import TodoItemTitle from '~/todos/components/todo_item_title.vue';
import TodoItemBody from '~/todos/components/todo_item_body.vue';
import TodoItemTimestamp from '~/todos/components/todo_item_timestamp.vue';
import TodoItemActions from '~/todos/components/todo_item_actions.vue';
import { TODO_STATE_DONE, TODO_STATE_PENDING } from '~/todos/constants';

describe('TodoItem', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(TodoItem, {
      propsData: {
        currentUserId: '1',
        todo: {
          id: '1',
          state: TODO_STATE_PENDING,
          targetType: 'Issue',
          targetUrl: '/project/issue/1',
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

  it('renders TodoItemTitle component', () => {
    createComponent();
    expect(wrapper.findComponent(TodoItemTitle).exists()).toBe(true);
  });

  it('renders TodoItemBody component', () => {
    createComponent();
    expect(wrapper.findComponent(TodoItemBody).exists()).toBe(true);
  });

  it('renders TodoItemTimestamp component', () => {
    createComponent();
    expect(wrapper.findComponent(TodoItemTimestamp).exists()).toBe(true);
  });

  it('renders TodoItemActions component', () => {
    createComponent();
    expect(wrapper.findComponent(TodoItemActions).exists()).toBe(true);
  });

  describe('state based style', () => {
    it('applies background when todo is done', () => {
      createComponent({ todo: { state: TODO_STATE_DONE } });
      expect(wrapper.attributes('class')).toContain('gl-bg-subtle');
    });

    it('applies no background when todo is pending', () => {
      createComponent({ todo: { state: TODO_STATE_PENDING } });
      expect(wrapper.attributes('class')).not.toContain('gl-bg-subtle');
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
    await todoItemActions.vm.$emit('change', '1', true);
    expect(wrapper.emitted('change')).toEqual([['1', true]]);
  });
});
