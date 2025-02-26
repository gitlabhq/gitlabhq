import { GlSprintf } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useFakeDate } from 'helpers/fake_date';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import TodosBulkBar from '~/todos/components/todos_bulk_bar.vue';
import SnoozeTimePicker from '~/todos/components/todo_snooze_until_picker.vue';
import { TABS_INDICES } from '~/todos/constants';
import bulkResolveMutation from '~/todos/components/mutations/bulk_resolve_todos.mutation.graphql';
import bulkRestoreMutation from '~/todos/components/mutations/undo_mark_all_as_done.mutation.graphql';
import bulkSnoozeMutation from '~/todos/components/mutations/bulk_snooze_todos.mutation.graphql';
import bulkUnsnoozeMutation from '~/todos/components/mutations/bulk_unsnooze_todos.mutation.graphql';

Vue.use(VueApollo);

describe('TodosBulkBar', () => {
  let wrapper;
  const mockToastShow = jest.fn().mockReturnValue({ hide: jest.fn() });

  const bulkResolveMutationSuccessHandler = jest.fn().mockResolvedValue({
    data: {
      bulkResolveTodos: {
        todos: [
          { id: 'gid://gitlab/Todo/1', state: 'done' },
          { id: 'gid://gitlab/Todo/2', state: 'done' },
        ],
        errors: [],
      },
    },
  });

  const bulkRestoreMutationSuccessHandler = jest.fn().mockResolvedValue({
    data: {
      undoMarkAllAsDone: {
        todos: [
          { id: 'gid://gitlab/Todo/1', state: 'pending' },
          { id: 'gid://gitlab/Todo/2', state: 'pending' },
        ],
        errors: [],
      },
    },
  });

  const bulkSnoozeMutationSuccessHandler = jest.fn().mockResolvedValue({
    data: {
      bulkSnoozeTodos: {
        todos: [
          { id: 'gid://gitlab/Todo/1', state: 'pending' },
          { id: 'gid://gitlab/Todo/2', state: 'pending' },
        ],
        errors: [],
      },
    },
  });

  const bulkUnsnoozeMutationSuccessHandler = jest.fn().mockResolvedValue({
    data: {
      bulkUnsnoozeTodos: {
        todos: [
          { id: 'gid://gitlab/Todo/1', state: 'pending' },
          { id: 'gid://gitlab/Todo/2', state: 'pending' },
        ],
        errors: [],
      },
    },
  });

  const createComponent = (props = {}) => {
    const mockApollo = createMockApollo([
      [bulkResolveMutation, bulkResolveMutationSuccessHandler],
      [bulkRestoreMutation, bulkRestoreMutationSuccessHandler],
      [bulkSnoozeMutation, bulkSnoozeMutationSuccessHandler],
      [bulkUnsnoozeMutation, bulkUnsnoozeMutationSuccessHandler],
    ]);

    wrapper = shallowMountExtended(TodosBulkBar, {
      apolloProvider: mockApollo,
      propsData: {
        ids: ['1', '2'],
        tab: TABS_INDICES.pending,
        ...props,
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findSnoozeButton = () => wrapper.findComponent(SnoozeTimePicker);
  const findUnsnoozeButton = () => wrapper.findByTestId('bulk-action-unsnooze');
  const findResolveButton = () => wrapper.findByTestId('bulk-action-resolve');
  const findRestoreButton = () => wrapper.findByTestId('bulk-action-restore');

  it('shows number of selected items', () => {
    createComponent({ ids: ['1', '2', '3'] });
    expect(wrapper.findByTestId('selected-count').text()).toMatch(/3\s+selected/);
  });

  describe('button visibility', () => {
    it.each([
      [
        'pending',
        {
          snooze: true,
          unsnooze: false,
          resolve: true,
          restore: false,
        },
      ],
      [
        'snoozed',
        {
          snooze: false,
          unsnooze: true,
          resolve: true,
          restore: false,
        },
      ],
      [
        'done',
        {
          snooze: false,
          unsnooze: false,
          resolve: false,
          restore: true,
        },
      ],
    ])('shows correct buttons for %s tab', (tabName, expected) => {
      createComponent({ tab: TABS_INDICES[tabName] });

      expect(findSnoozeButton().exists()).toBe(expected.snooze);
      expect(findUnsnoozeButton().exists()).toBe(expected.unsnooze);
      expect(findResolveButton().exists()).toBe(expected.resolve);
      expect(findRestoreButton().exists()).toBe(expected.restore);
    });
  });

  describe('button actions', () => {
    describe('bulk-resolve button', () => {
      beforeEach(async () => {
        createComponent();
        findResolveButton().vm.$emit('click');
        await waitForPromises();
      });

      it('triggers the bulkResolve mutation with the correct args', () => {
        expect(bulkResolveMutationSuccessHandler).toHaveBeenCalledWith({ todoIDs: ['1', '2'] });
      });

      it('emits a change event', () => {
        expect(wrapper.emitted('change')).toHaveLength(1);
      });

      it('shows a toast with undo action', () => {
        expect(mockToastShow).toHaveBeenCalledWith('Marked 2 to-dos as done', {
          action: {
            onClick: expect.any(Function),
            text: 'Undo',
          },
        });
      });
    });

    describe('bulk-restore button', () => {
      beforeEach(async () => {
        createComponent({ tab: TABS_INDICES.done });
        findRestoreButton().vm.$emit('click');
        await waitForPromises();
      });

      it('triggers the bulkRestore mutation with the correct args', () => {
        expect(bulkRestoreMutationSuccessHandler).toHaveBeenCalledWith({ todoIDs: ['1', '2'] });
      });

      it('emits a change event', () => {
        expect(wrapper.emitted('change')).toHaveLength(1);
      });

      it('shows a toast with undo action', () => {
        expect(mockToastShow).toHaveBeenCalledWith('Restored 2 to-dos', {
          action: {
            onClick: expect.any(Function),
            text: 'Undo',
          },
        });
      });
    });

    describe('bulk-unsnooze button', () => {
      beforeEach(async () => {
        createComponent({ tab: TABS_INDICES.snoozed });
        findUnsnoozeButton().vm.$emit('click');
        await waitForPromises();
      });

      it('triggers the bulkUnsnooze mutation with the correct args', () => {
        expect(bulkUnsnoozeMutationSuccessHandler).toHaveBeenCalledWith({ todoIDs: ['1', '2'] });
      });

      it('emits a change event', () => {
        expect(wrapper.emitted('change')).toHaveLength(1);
      });

      it('shows a toast without undo action', () => {
        expect(mockToastShow).toHaveBeenCalledWith('Removed snooze from 2 to-dos', {});
      });
    });

    describe('bulk-snooze dropdown', () => {
      const mockCurrentTime = new Date('2025-02-24T14:00:00');
      const oneHourFromNow = new Date('2025-02-24T15:00:00');

      useFakeDate(mockCurrentTime);

      beforeEach(async () => {
        createComponent({ tab: TABS_INDICES.pending });
        findSnoozeButton().vm.$emit('snooze-until', oneHourFromNow);
        await waitForPromises();
      });

      it('triggers the bulkSnooze mutation with the correct args', () => {
        expect(bulkSnoozeMutationSuccessHandler).toHaveBeenCalledWith({
          todoIDs: ['1', '2'],
          snoozeUntil: oneHourFromNow,
        });
      });

      it('emits a change event', () => {
        expect(wrapper.emitted('change')).toHaveLength(1);
      });

      it('shows a toast with undo action', () => {
        expect(mockToastShow).toHaveBeenCalledWith('Snoozed 2 to-dos', {
          action: {
            onClick: expect.any(Function),
            text: 'Undo',
          },
        });
      });
    });
  });
});
