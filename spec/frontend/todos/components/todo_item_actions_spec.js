import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import TodoItemActions from '~/todos/components/todo_item_actions.vue';
import SnoozeTodoDropdown from '~/todos/components/snooze_todo_dropdown.vue';

import { TODO_STATE_DONE, TODO_STATE_PENDING } from '~/todos/constants';

describe('TodoItemActions', () => {
  let wrapper;
  const mockTodo = {
    id: 'gid://gitlab/Todo/1',
    state: TODO_STATE_PENDING,
  };

  const createComponent = ({ props = {}, todosSnoozingEnabled = false } = {}) => {
    wrapper = shallowMount(TodoItemActions, {
      propsData: {
        todo: mockTodo,
        isSnoozed: false,
        ...props,
      },
      provide: {
        glFeatures: {
          todosSnoozing: todosSnoozingEnabled,
        },
      },
    });
  };

  const findSnoozeTodoDropdown = () => wrapper.findComponent(SnoozeTodoDropdown);

  it('sets correct icon for pending todo action button', () => {
    createComponent();
    expect(wrapper.findComponent(GlButton).props('icon')).toBe('check');
  });

  it('sets correct icon for done todo action button', () => {
    createComponent({ props: { todo: { ...mockTodo, state: TODO_STATE_DONE } } });
    expect(wrapper.findComponent(GlButton).props('icon')).toBe('redo');
  });

  it('sets correct aria-label for pending todo', () => {
    createComponent();
    expect(wrapper.findComponent(GlButton).attributes('aria-label')).toBe('Mark as done');
  });

  it('sets correct aria-label for done todo', () => {
    createComponent({ props: { todo: { ...mockTodo, state: TODO_STATE_DONE } } });
    expect(wrapper.findComponent(GlButton).attributes('aria-label')).toBe('Undo');
  });

  describe('tooltipTitle', () => {
    it('returns "Mark as done" for pending todo', () => {
      createComponent();
      expect(wrapper.vm.tooltipTitle).toBe('Mark as done');
    });

    it('returns "Undo" for done todo', () => {
      createComponent({ props: { todo: { ...mockTodo, state: TODO_STATE_DONE } } });
      expect(wrapper.vm.tooltipTitle).toBe('Undo');
    });
  });

  describe('snoozing dropdown', () => {
    describe('when the `todosSnoozing` feature flag is disabled', () => {
      it('never renders the dropdown', () => {
        createComponent({ todosSnoozingEnabled: false, props: { isSnoozed: false } });

        expect(findSnoozeTodoDropdown().exists()).toBe(false);
      });
    });

    it('renders the dropdown if `isSnoozed` is `false` and the todo is pending', () => {
      createComponent({ todosSnoozingEnabled: true, props: { isSnoozed: false } });

      expect(findSnoozeTodoDropdown().exists()).toBe(true);
    });

    it('does not render the dropdown if `isSnoozed` is `true` and the todo is pending', () => {
      createComponent({ todosSnoozingEnabled: true, props: { isSnoozed: true } });

      expect(findSnoozeTodoDropdown().exists()).toBe(false);
    });

    it('does not render the dropdown if `isSnoozed` is `false` and the todo is done', () => {
      createComponent({
        todosSnoozingEnabled: true,
        props: { isSnoozed: false, todo: { ...mockTodo, state: TODO_STATE_DONE } },
      });

      expect(findSnoozeTodoDropdown().exists()).toBe(false);
    });
  });
});
