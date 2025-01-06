import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import TodoItemActions from '~/todos/components/todo_item_actions.vue';
import SnoozeTodoDropdown from '~/todos/components/snooze_todo_dropdown.vue';
import { TODO_STATE_DONE, TODO_STATE_PENDING } from '~/todos/constants';
import unSnoozeTodoMutation from '~/todos/components/mutations/un_snooze_todo.mutation.graphql';

Vue.use(VueApollo);

describe('TodoItemActions', () => {
  let wrapper;
  const mockCurrentTime = new Date('2024-12-18T13:24:00');
  const mockTodo = {
    id: 'gid://gitlab/Todo/1',
    state: TODO_STATE_PENDING,
  };
  const mockToastShow = jest.fn();

  const unSnoozeTodoMutationSuccessHandler = jest.fn().mockResolvedValue({
    data: {
      todoUnSnooze: {
        todo: { ...mockTodo, snoozedUntil: mockCurrentTime },
        errors: [],
      },
    },
  });

  const createComponent = ({
    props = {},
    unSnoozeTodoMutationHandler = unSnoozeTodoMutationSuccessHandler,
    todosSnoozingEnabled = false,
  } = {}) => {
    const mockApollo = createMockApollo();

    mockApollo.defaultClient.setRequestHandler(unSnoozeTodoMutation, unSnoozeTodoMutationHandler);

    wrapper = shallowMountExtended(TodoItemActions, {
      apolloProvider: mockApollo,
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
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
    });
  };

  const findSnoozeTodoDropdown = () => wrapper.findComponent(SnoozeTodoDropdown);
  const findUnSnoozeButton = () => wrapper.findByTestId('un-snooze-button');

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

  describe('un-snooze button', () => {
    it('renders if the to-do item is snoozed', () => {
      createComponent({ todosSnoozingEnabled: true, props: { isSnoozed: true } });

      expect(findUnSnoozeButton().exists()).toBe(true);
    });

    it('has the correct attributes', () => {
      createComponent({ todosSnoozingEnabled: true, props: { isSnoozed: true } });

      expect(findUnSnoozeButton().attributes()).toMatchObject({
        icon: 'time-out',
        title: 'Remove snooze',
        'aria-label': 'Remove snooze',
      });
    });

    it('triggers the un-snooze mutation', () => {
      createComponent({ todosSnoozingEnabled: true, props: { isSnoozed: true } });

      findUnSnoozeButton().vm.$emit('click');

      expect(unSnoozeTodoMutationSuccessHandler).toHaveBeenCalledWith({
        todoId: mockTodo.id,
      });
    });

    it('shows an error when the to un-snooze mutation returns some errors', async () => {
      createComponent({
        todosSnoozingEnabled: true,
        props: { isSnoozed: true },
        unSnoozeTodoMutationHandler: jest.fn().mockResolvedValue({
          data: {
            todoUnSnooze: {
              todo: { ...mockTodo },
              errors: ['Could not un-snooze todo-item.'],
            },
          },
        }),
      });

      findUnSnoozeButton().vm.$emit('click');
      await waitForPromises();

      expect(mockToastShow).toHaveBeenCalledWith('Failed to un-snooze todo. Try again later.', {
        variant: 'danger',
      });
    });

    it('shows an error when it fails to un-snooze the to-do item', async () => {
      createComponent({
        todosSnoozingEnabled: true,
        props: { isSnoozed: true },
        unSnoozeTodoMutationHandler: jest.fn().mockRejectedValue(),
      });

      findUnSnoozeButton().vm.$emit('click');
      await waitForPromises();

      expect(mockToastShow).toHaveBeenCalledWith('Failed to un-snooze todo. Try again later.', {
        variant: 'danger',
      });
    });

    it('has a tooltip attached', () => {
      createComponent({ todosSnoozingEnabled: true, props: { isSnoozed: true } });

      const tooltip = getBinding(findUnSnoozeButton().element, 'gl-tooltip');

      expect(tooltip).toBeDefined();
    });
  });

  describe('when the `todosSnoozing` feature flag is disabled', () => {
    it('never renders the dropdown', () => {
      createComponent({ todosSnoozingEnabled: false, props: { isSnoozed: false } });

      expect(findSnoozeTodoDropdown().exists()).toBe(false);
    });

    it('never renders the un-snooze button', () => {
      createComponent({ todosSnoozingEnabled: false, props: { isSnoozed: true } });

      expect(findUnSnoozeButton().exists()).toBe(false);
    });
  });
});
