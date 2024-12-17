import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import TodoItemActions from '~/todos/components/todo_item_actions.vue';
import { TODO_STATE_DONE, TODO_STATE_PENDING } from '~/todos/constants';

describe('TodoItemActions', () => {
  let wrapper;
  const mockTodo = {
    id: 'gid://gitlab/Todo/1',
    state: TODO_STATE_PENDING,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(TodoItemActions, {
      propsData: {
        todo: mockTodo,
        ...props,
      },
    });
  };

  it('sets correct icon for pending todo action button', () => {
    createComponent();
    expect(wrapper.findComponent(GlButton).props('icon')).toBe('check');
  });

  it('sets correct icon for done todo action button', () => {
    createComponent({ todo: { ...mockTodo, state: TODO_STATE_DONE } });
    expect(wrapper.findComponent(GlButton).props('icon')).toBe('redo');
  });

  it('sets correct aria-label for pending todo', () => {
    createComponent();
    expect(wrapper.findComponent(GlButton).attributes('aria-label')).toBe('Mark as done');
  });

  it('sets correct aria-label for done todo', () => {
    createComponent({ todo: { ...mockTodo, state: TODO_STATE_DONE } });
    expect(wrapper.findComponent(GlButton).attributes('aria-label')).toBe('Undo');
  });

  describe('tooltipTitle', () => {
    it('returns "Mark as done" for pending todo', () => {
      createComponent();
      expect(wrapper.vm.tooltipTitle).toBe('Mark as done');
    });

    it('returns "Undo" for done todo', () => {
      createComponent({ todo: { ...mockTodo, state: TODO_STATE_DONE } });
      expect(wrapper.vm.tooltipTitle).toBe('Undo');
    });
  });
});
