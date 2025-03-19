import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ToggleSnoozedStatus from '~/todos/components/toggle_snoozed_status.vue';
import { TODO_STATE_PENDING } from '~/todos/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import snoozeTodoMutation from '~/todos/components/mutations/snooze_todo.mutation.graphql';
import unSnoozeTodoMutation from '~/todos/components/mutations/un_snooze_todo.mutation.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import { useFakeDate } from 'helpers/fake_date';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { mockTracking, unmockTracking } from 'jest/__helpers__/tracking_helper';
import SnoozeTimePicker from '~/todos/components/todo_snooze_until_picker.vue';
import { updateGlobalTodoCount } from '~/sidebar/utils';

Vue.use(VueApollo);
jest.mock('~/sidebar/utils');

describe('ToggleSnoozedStatus', () => {
  let wrapper;
  const mockTodo = {
    id: 'gid://gitlab/Todo/1',
    state: TODO_STATE_PENDING,
  };
  const mockCurrentTime = new Date('2024-12-18T13:24:00');
  const mockToastShow = jest.fn();

  useFakeDate(mockCurrentTime);

  const snoozeTodoMutationSuccessHandler = jest.fn().mockResolvedValue({
    data: {
      todoSnooze: {
        todo: {
          ...mockTodo,
          snoozedUntil: mockCurrentTime,
        },
        errors: [],
      },
    },
  });
  const unSnoozeTodoMutationSuccessHandler = jest.fn().mockResolvedValue({
    data: {
      todoUnSnooze: {
        todo: { ...mockTodo, snoozedUntil: mockCurrentTime },
        errors: [],
      },
    },
  });

  const findSnoozeTimePicker = () => wrapper.findComponent(SnoozeTimePicker);
  const findUnSnoozeButton = () => wrapper.findByTestId('un-snooze-button');

  const createComponent = ({
    props = {},
    snoozeTodoMutationHandler = snoozeTodoMutationSuccessHandler,
    unSnoozeTodoMutationHandler = unSnoozeTodoMutationSuccessHandler,
  } = {}) => {
    const mockApollo = createMockApollo();

    mockApollo.defaultClient.setRequestHandler(snoozeTodoMutation, snoozeTodoMutationHandler);
    mockApollo.defaultClient.setRequestHandler(unSnoozeTodoMutation, unSnoozeTodoMutationHandler);

    wrapper = shallowMountExtended(ToggleSnoozedStatus, {
      apolloProvider: mockApollo,
      propsData: {
        todo: mockTodo,
        ...props,
      },
      provide: {
        currentTime: mockCurrentTime,
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

  describe('snoozing dropdown', () => {
    it('renders the dropdown if `isSnoozed` is `false` and the todo is pending', () => {
      createComponent({ props: { isSnoozed: false, isPending: true } });

      expect(findSnoozeTimePicker().exists()).toBe(true);
    });

    it('does not render the dropdown if `isSnoozed` is `true` and the todo is pending', () => {
      createComponent({ props: { isSnoozed: true, isPending: true } });

      expect(findSnoozeTimePicker().exists()).toBe(false);
    });

    it('does not render the dropdown if `isSnoozed` is `false` and the todo is done', () => {
      createComponent({
        props: { isSnoozed: false, isPending: false },
      });

      expect(findSnoozeTimePicker().exists()).toBe(false);
    });
  });

  it('triggers the snooze mutation and optimistic count update', () => {
    createComponent({ props: { isSnoozed: false, isPending: true } });

    findSnoozeTimePicker().vm.$emit('snooze-until', mockCurrentTime);

    expect(snoozeTodoMutationSuccessHandler).toHaveBeenCalledWith({
      snoozeUntil: mockCurrentTime,
      todoId: mockTodo.id,
    });
    expect(updateGlobalTodoCount).toHaveBeenCalledWith(-1);
  });

  it('shows an error when the to snooze mutation returns some errors', async () => {
    createComponent({
      props: { isSnoozed: false, isPending: true },
      snoozeTodoMutationHandler: jest.fn().mockResolvedValue({
        data: {
          todoSnooze: {
            todo: { ...mockTodo },
            errors: ['Could not snooze todo-item.'],
          },
        },
      }),
    });
    findSnoozeTimePicker().vm.$emit('snooze-until', mockCurrentTime);
    await waitForPromises();

    expect(mockToastShow).toHaveBeenCalledWith('Failed to snooze todo. Try again later.', {
      variant: 'danger',
    });
  });

  it('shows an error when it fails to snooze the to-do item', async () => {
    createComponent({
      props: { isSnoozed: false, isPending: true },
      snoozeTodoMutationHandler: jest.fn().mockRejectedValue(),
    });
    findSnoozeTimePicker().vm.$emit('snooze-until', mockCurrentTime);
    await waitForPromises();

    expect(mockToastShow).toHaveBeenCalledWith('Failed to snooze todo. Try again later.', {
      variant: 'danger',
    });
  });

  describe('un-snooze button', () => {
    it('renders if the to-do item is snoozed', () => {
      createComponent({ props: { isSnoozed: true, isPending: true } });

      expect(findUnSnoozeButton().exists()).toBe(true);
    });

    it('has the correct attributes', () => {
      createComponent({ props: { isSnoozed: true, isPending: true } });

      expect(findUnSnoozeButton().attributes()).toMatchObject({
        icon: 'time-out',
        title: 'Remove snooze',
        'aria-label': 'Remove snooze',
      });
    });

    it('triggers the un-snooze mutation and optimistic count update', () => {
      createComponent({ props: { isSnoozed: true, isPending: true } });

      findUnSnoozeButton().vm.$emit('click');

      expect(unSnoozeTodoMutationSuccessHandler).toHaveBeenCalledWith({
        todoId: mockTodo.id,
      });
      expect(updateGlobalTodoCount).toHaveBeenCalledWith(1);
    });

    it('shows an error when the to un-snooze mutation returns some errors', async () => {
      createComponent({
        props: { isSnoozed: true, isPending: true },
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
        props: { isSnoozed: true, isPending: true },
        unSnoozeTodoMutationHandler: jest.fn().mockRejectedValue(),
      });
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      findUnSnoozeButton().vm.$emit('click');
      await waitForPromises();

      expect(mockToastShow).toHaveBeenCalledWith('Failed to un-snooze todo. Try again later.', {
        variant: 'danger',
      });
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_todo_item_action', {
        label: 'remove_snooze',
      });

      unmockTracking();
    });

    it('has a tooltip attached', () => {
      createComponent({ props: { isSnoozed: true, isPending: true } });

      const tooltip = getBinding(findUnSnoozeButton().element, 'gl-tooltip');

      expect(tooltip).toBeDefined();
    });
  });
});
