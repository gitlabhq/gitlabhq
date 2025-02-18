import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import TodoItemActions from '~/todos/components/todo_item_actions.vue';
import ToggleSnoozedStatus from '~/todos/components/toggle_snoozed_status.vue';
import { TODO_STATE_DONE, TODO_STATE_PENDING } from '~/todos/constants';
import markAsDoneMutation from '~/todos/components/mutations/mark_as_done.mutation.graphql';
import markAsPendingMutation from '~/todos/components/mutations/mark_as_pending.mutation.graphql';

Vue.use(VueApollo);

describe('TodoItemActions', () => {
  let wrapper;
  const mockTodo = {
    id: 'gid://gitlab/Todo/1',
    state: TODO_STATE_PENDING,
  };
  const mockToastShow = jest.fn();

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
    it('marks pending todos as done and emits the `change` event', async () => {
      createComponent();
      findToggleStatusButton().vm.$emit('click');
      await waitForPromises();

      expect(markAsDoneMutationSuccessHandler).toHaveBeenCalled();
      expect(wrapper.emitted('change')).toHaveLength(1);
    });

    it('marks done todos as pending and emits the `change` event', async () => {
      createComponent({ props: { todo: { ...mockTodo, state: TODO_STATE_DONE } } });
      findToggleStatusButton().vm.$emit('click');
      await waitForPromises();

      expect(markAsPendingMutationSuccessHandler).toHaveBeenCalled();
      expect(wrapper.emitted('change')).toHaveLength(1);
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
