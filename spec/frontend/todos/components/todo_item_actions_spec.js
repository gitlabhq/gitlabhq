import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import TodoItemActions from '~/todos/components/todo_item_actions.vue';
import ToggleSnoozedStatus from '~/todos/components/toggle_snoozed_status.vue';
import {
  TODO_STATE_DONE,
  TODO_STATE_PENDING,
  TODO_ACTION_TYPE_ADDED_APPROVER,
} from '~/todos/constants';
import markAsDoneMutation from '~/todos/components/mutations/mark_as_done.mutation.graphql';
import markAsPendingMutation from '~/todos/components/mutations/mark_as_pending.mutation.graphql';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { updateGlobalTodoCount } from '~/sidebar/utils';

Vue.use(VueApollo);
jest.mock('~/sidebar/utils');

describe('TodoItemActions', () => {
  let wrapper;
  const mockTodo = {
    id: 'gid://gitlab/Todo/1',
    state: TODO_STATE_PENDING,
    action: TODO_ACTION_TYPE_ADDED_APPROVER,
  };
  const mockToastShow = jest.fn();
  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  const markAsDoneMutationSuccessHandler = jest.fn().mockResolvedValue({
    data: {
      toggleStatus: {
        todo: { ...mockTodo, state: TODO_STATE_DONE },
        errors: [],
      },
    },
  });
  const markAsPendingMutationSuccessHandler = jest.fn().mockResolvedValue({
    data: {
      toggleStatus: {
        todo: { ...mockTodo, state: TODO_STATE_PENDING },
        errors: [],
      },
    },
  });

  const createComponent = ({ props = {} } = {}) => {
    const mockApollo = createMockApollo([
      [markAsDoneMutation, markAsDoneMutationSuccessHandler],
      [markAsPendingMutation, markAsPendingMutationSuccessHandler],
    ]);

    wrapper = shallowMountExtended(TodoItemActions, {
      apolloProvider: mockApollo,
      propsData: {
        todo: mockTodo,
        isSnoozed: false,
        ...props,
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
    });
  };

  const findToggleSnoozedStatus = () => wrapper.findComponent(ToggleSnoozedStatus);
  const findToggleStatusButton = () => wrapper.findByTestId('toggle-status-button');

  it('sets correct icon for pending todo action button', () => {
    createComponent();
    expect(findToggleStatusButton().props('icon')).toBe('check');
  });

  it('sets correct icon for done todo action button', () => {
    createComponent({ props: { todo: { ...mockTodo, state: TODO_STATE_DONE } } });
    expect(findToggleStatusButton().props('icon')).toBe('redo');
  });

  it('sets correct aria-label for pending todo', () => {
    createComponent();
    expect(findToggleStatusButton().attributes('aria-label')).toBe('Mark as done');
  });

  it('sets correct aria-label for done todo', () => {
    createComponent({ props: { todo: { ...mockTodo, state: TODO_STATE_DONE } } });
    expect(findToggleStatusButton().attributes('aria-label')).toBe('Undo');
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

  describe('toggling the status', () => {
    it('marks pending todos as done, emits the `change` event, and optimistic update of the count', async () => {
      createComponent();
      findToggleStatusButton().vm.$emit('click');
      await waitForPromises();

      expect(markAsDoneMutationSuccessHandler).toHaveBeenCalled();
      expect(wrapper.emitted('change')).toHaveLength(1);
      expect(updateGlobalTodoCount).toHaveBeenCalledWith(-1);
    });

    it('marks snoozed todos as done and emits the `change` event, and NO optimistic update of the count', async () => {
      createComponent({ props: { isSnoozed: true } });
      findToggleStatusButton().vm.$emit('click');
      await waitForPromises();

      expect(markAsDoneMutationSuccessHandler).toHaveBeenCalled();
      expect(wrapper.emitted('change')).toHaveLength(1);
      expect(updateGlobalTodoCount).not.toHaveBeenCalledWith();
    });

    it('marks done todos as pending and emits the `change` event, and optimistic update of the count', async () => {
      createComponent({ props: { todo: { ...mockTodo, state: TODO_STATE_DONE } } });
      findToggleStatusButton().vm.$emit('click');
      await waitForPromises();

      expect(markAsPendingMutationSuccessHandler).toHaveBeenCalled();
      expect(wrapper.emitted('change')).toHaveLength(1);
      expect(updateGlobalTodoCount).toHaveBeenCalledWith(+1);
    });

    it('should track an event', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      createComponent({ props: { todo: { ...mockTodo, state: TODO_STATE_DONE } } });
      findToggleStatusButton().vm.$emit('click');

      expect(trackEventSpy).toHaveBeenCalledWith(
        'click_todo_item_action',
        {
          label: 'mark_pending',
          property: TODO_ACTION_TYPE_ADDED_APPROVER,
        },
        undefined,
      );
    });
  });

  describe('toggling the snoozed status', () => {
    it('renders the ToggleSnoozedStatus component', () => {
      createComponent();

      expect(findToggleSnoozedStatus().exists()).toBe(true);
    });

    it.each(['snoozed', 'un-snoozed'])(
      'emits the `change` event when it receives the `%s` event',
      (event) => {
        createComponent();

        expect(wrapper.emitted('change')).toBeUndefined();

        findToggleSnoozedStatus().vm.$emit(event);

        expect(wrapper.emitted('change')).toHaveLength(1);

        expect(findToggleSnoozedStatus().exists()).toBe(true);
      },
    );
  });
});
