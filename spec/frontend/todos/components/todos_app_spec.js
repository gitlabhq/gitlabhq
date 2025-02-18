import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlTabs, GlFormCheckbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { ignoreConsoleMessages } from 'helpers/console_watcher';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import TodosApp from '~/todos/components/todos_app.vue';
import TodoItem from '~/todos/components/todo_item.vue';
import TodosFilterBar from '~/todos/components/todos_filter_bar.vue';
import TodosMarkAllDoneButton from '~/todos/components/todos_mark_all_done_button.vue';
import TodosBulkBar from '~/todos/components/todos_bulk_bar.vue';
import TodosPagination, { CURSOR_CHANGED_EVENT } from '~/todos/components/todos_pagination.vue';
import getTodosQuery from '~/todos/components/queries/get_todos.query.graphql';
import { INSTRUMENT_TAB_LABELS, STATUS_BY_TAB, TODO_WAIT_BEFORE_RELOAD } from '~/todos/constants';
import { mockTracking, unmockTracking } from 'jest/__helpers__/tracking_helper';
import getPendingTodosCount from '~/todos/components/queries/get_pending_todos_count.query.graphql';
import { todosResponse, getPendingTodosCountResponse } from '../mock_data';

Vue.use(VueApollo);

describe('TodosApp', () => {
  let wrapper;

  const todosQuerySuccessHandler = jest.fn().mockResolvedValue(todosResponse);
  const todosCountsQuerySuccessHandler = jest.fn().mockResolvedValue(getPendingTodosCountResponse);

  const createComponent = ({
    todosQueryHandler = todosQuerySuccessHandler,
    todosCountsQueryHandler = todosCountsQuerySuccessHandler,
    featureFlags = { todosBulkActions: false },
  } = {}) => {
    const mockApollo = createMockApollo();
    mockApollo.defaultClient.setRequestHandler(getTodosQuery, todosQueryHandler);
    mockApollo.defaultClient.setRequestHandler(getPendingTodosCount, todosCountsQueryHandler);

    wrapper = shallowMountExtended(TodosApp, {
      apolloProvider: mockApollo,
      provide: {
        glFeatures: featureFlags,
      },
    });
  };

  const findTodoItems = () => wrapper.findAllComponents(TodoItem);
  const findFirstTodoItem = () => wrapper.findComponent(TodoItem);
  const findGlTabs = () => wrapper.findComponent(GlTabs);
  const findFilterBar = () => wrapper.findComponent(TodosFilterBar);
  const findMarkAllDoneButton = () => wrapper.findComponent(TodosMarkAllDoneButton);
  const findRefreshButton = () => wrapper.findByTestId('refresh-todos');
  const findPendingTodosCount = () => wrapper.findByTestId('pending-todos-count');
  const findTodoItemListContainer = () => wrapper.findByTestId('todo-item-list-container');
  const findPagination = () => wrapper.findComponent(TodosPagination);

  ignoreConsoleMessages([/\[Vue warn\]: \(deprecation TRANSITION_GROUP_ROOT\)/]);

  it('should have a tracking event for each tab', () => {
    expect(STATUS_BY_TAB.length).toBe(INSTRUMENT_TAB_LABELS.length);
  });

  it('shows a loading state while fetching todos', () => {
    createComponent();

    expect(findTodoItems().length).toBe(0);
    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  it('renders todo items once the query has resolved', async () => {
    createComponent();
    await waitForPromises();

    expect(findTodoItems().length).toBe(todosResponse.data.currentUser.todos.nodes.length);
    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
  });

  it('shows pagination for the todos', async () => {
    createComponent();
    await waitForPromises();

    expect(findPagination().exists()).toBe(true);
  });

  it('fetches the todos when pagination changes', async () => {
    createComponent();
    await waitForPromises();

    const newCursor = { first: 50, after: 'cursor-1' };
    findPagination().vm.$emit(CURSOR_CHANGED_EVENT, newCursor);
    await waitForPromises();

    expect(todosQuerySuccessHandler).toHaveBeenLastCalledWith(
      expect.objectContaining({
        ...newCursor,
      }),
    );
  });

  it('fetches the todos and counts when filters change', async () => {
    createComponent();

    const filters = {
      groupId: ['1'],
      projectId: ['2'],
      authorId: ['3'],
      type: ['4'],
      action: ['assigned'],
      sort: 'CREATED_DESC',
    };
    findFilterBar().vm.$emit('filters-changed', filters);
    await waitForPromises();

    expect(todosQuerySuccessHandler).toHaveBeenLastCalledWith({
      ...filters,
      state: ['pending'],
      first: 20,
      last: null,
      after: null,
      before: null,
    });
    expect(todosCountsQuerySuccessHandler).toHaveBeenLastCalledWith(filters);
  });

  it('re-fetches the pending todos count when mark all done button is clicked', async () => {
    createComponent();
    await waitForPromises();

    expect(todosCountsQuerySuccessHandler).toHaveBeenCalledTimes(1);

    findMarkAllDoneButton().vm.$emit('change');

    expect(todosCountsQuerySuccessHandler).toHaveBeenCalledTimes(2);
  });

  it('refreshes count and list', async () => {
    createComponent();
    await waitForPromises();

    expect(todosCountsQuerySuccessHandler).toHaveBeenCalledTimes(1);
    expect(todosQuerySuccessHandler).toHaveBeenCalledTimes(1);

    findRefreshButton().vm.$emit('click', new Event('click'));

    expect(todosCountsQuerySuccessHandler).toHaveBeenCalledTimes(2);
    expect(todosQuerySuccessHandler).toHaveBeenCalledTimes(2);
  });

  it('shows the pending todos count once it has been fetched', async () => {
    createComponent();

    expect(findPendingTodosCount().text()).toBe('-');

    await waitForPromises();

    expect(findPendingTodosCount().text()).toBe(
      String(getPendingTodosCountResponse.data.currentUser.todos.count),
    );
  });

  it('refetches todos when page becomes visible again', async () => {
    createComponent();

    // Wait and account for initial query
    await waitForPromises();
    expect(todosQuerySuccessHandler).toHaveBeenCalledTimes(1);
    expect(todosCountsQuerySuccessHandler).toHaveBeenCalledTimes(1);

    // Make sure we don't refetch when document became hidden
    jest.spyOn(document, 'hidden', 'get').mockReturnValue(true);
    document.dispatchEvent(new Event('visibilitychange'));
    await waitForPromises();
    expect(todosQuerySuccessHandler).toHaveBeenCalledTimes(1);
    expect(todosCountsQuerySuccessHandler).toHaveBeenCalledTimes(1);

    // Expect refetch when document becomes visible
    jest.spyOn(document, 'hidden', 'get').mockReturnValue(false);
    document.dispatchEvent(new Event('visibilitychange'));
    await waitForPromises();
    expect(todosQuerySuccessHandler).toHaveBeenCalledTimes(2);
    expect(todosCountsQuerySuccessHandler).toHaveBeenCalledTimes(2);
  });

  it('refetches todos one second after the cursor leaves the list of todos', async () => {
    createComponent();

    // Wait and account for initial query
    await waitForPromises();
    expect(todosQuerySuccessHandler).toHaveBeenCalledTimes(1);
    expect(todosCountsQuerySuccessHandler).toHaveBeenCalledTimes(1);

    // Simulate interacting with a todo item then mousing out of the list zone
    findFirstTodoItem().vm.$emit('change');
    const list = findTodoItemListContainer();
    list.trigger('mouseleave');

    // Should refresh the count, but not the list
    await waitForPromises();
    expect(todosQuerySuccessHandler).toHaveBeenCalledTimes(1);
    expect(todosCountsQuerySuccessHandler).toHaveBeenCalledTimes(2);

    // Run out the clock
    jest.advanceTimersByTime(TODO_WAIT_BEFORE_RELOAD + 50); // 1s + some jitter

    // Refreshes the count and the list
    await waitForPromises();
    expect(todosQuerySuccessHandler).toHaveBeenCalledTimes(2);
    expect(todosCountsQuerySuccessHandler).toHaveBeenCalledTimes(3);
  });

  it('does not refresh todos after the cursor leaves the list of todos if nothing changed', async () => {
    createComponent();

    // Wait and account for initial query
    await waitForPromises();
    expect(todosQuerySuccessHandler).toHaveBeenCalledTimes(1);
    expect(todosCountsQuerySuccessHandler).toHaveBeenCalledTimes(1);

    // Simulate NOT interacting with a todo item then mousing out of the list zone
    const list = findTodoItemListContainer();
    list.trigger('mouseleave');

    // Should not update anything
    await waitForPromises();
    expect(todosQuerySuccessHandler).toHaveBeenCalledTimes(1);
    expect(todosCountsQuerySuccessHandler).toHaveBeenCalledTimes(1);

    // Run out the clock
    jest.advanceTimersByTime(TODO_WAIT_BEFORE_RELOAD + 50); // 1s + some jitter

    // Should not update anything
    await waitForPromises();
    expect(todosQuerySuccessHandler).toHaveBeenCalledTimes(1);
    expect(todosCountsQuerySuccessHandler).toHaveBeenCalledTimes(1);
  });

  it('passes the default status to the filter bar', () => {
    createComponent();

    expect(findFilterBar().props('todosStatus')).toEqual(['pending']);
  });

  it.each`
    tabIndex | status                 | label
    ${0}     | ${['pending']}         | ${'status_pending'}
    ${1}     | ${['pending']}         | ${'status_snoozed'}
    ${2}     | ${['done']}            | ${'status_done'}
    ${3}     | ${['pending', 'done']} | ${'status_all'}
  `(
    'sets the filter bar status to $status and tracks the event $label when the tab changes to index #$tabIndex',
    async ({ tabIndex, status, label }) => {
      createComponent();

      // Navigate to another tab that isn't the target
      findGlTabs().vm.$emit('input', tabIndex === 0 ? 1 : tabIndex - 1);
      await nextTick();

      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      findGlTabs().vm.$emit('input', tabIndex);
      await nextTick();

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'filter_todo_list', {
        label,
      });
      expect(findFilterBar().props('todosStatus')).toEqual(status);
      unmockTracking();
    },
  );

  it('syncs tab change to URL while leaving other params unchanged', () => {
    setWindowLocation('?group_id=123');
    createComponent();
    expect(window.location.search).toBe('?group_id=123');

    findGlTabs().vm.$emit('input', 1);
    expect(window.location.search).toBe('?group_id=123&state=snoozed');

    findGlTabs().vm.$emit('input', 2);
    expect(window.location.search).toBe('?group_id=123&state=done');

    findGlTabs().vm.$emit('input', 3);
    expect(window.location.search).toBe('?group_id=123&state=all');

    findGlTabs().vm.$emit('input', 0);
    expect(window.location.search).toBe('?group_id=123');
  });

  describe('reading `state` param from URL', () => {
    beforeEach(() => {
      setWindowLocation('?state=done');
    });

    it('activates correct tab', () => {
      createComponent();
      expect(findGlTabs().props('value')).toBe(2);
    });
  });

  describe('bulk selection', () => {
    beforeEach(async () => {
      createComponent({
        featureFlags: { todosBulkActions: true },
      });
      await waitForPromises();
    });

    const findSelectedTodoItems = () => findTodoItems().filter((item) => item.props('selected'));
    const findSelectAllCheckbox = () => wrapper.findComponent(GlFormCheckbox);
    const findBulkBar = () => wrapper.findComponent(TodosBulkBar);

    describe('select all checkbox', () => {
      it('is not visible when bulk actions feature flag is disabled', async () => {
        createComponent({
          featureFlags: { todosBulkActions: false },
        });
        await waitForPromises();

        expect(findSelectAllCheckbox().exists()).toBe(false);
      });

      it('is not visible on "All" tab', async () => {
        findGlTabs().vm.$emit('input', 3); // All tab
        await nextTick();

        expect(findSelectAllCheckbox().exists()).toBe(false);
      });

      it('is visible on other tabs', () => {
        expect(findSelectAllCheckbox().exists()).toBe(true);
      });

      it('becomes indeterminate when some but not all items are selected', async () => {
        findFirstTodoItem().vm.$emit(
          'select-change',
          todosResponse.data.currentUser.todos.nodes[0].id,
          true,
        );
        await nextTick();

        expect(findSelectAllCheckbox().attributes()).toMatchObject({
          indeterminate: 'true',
        });
      });
    });

    describe('selection state', () => {
      it('clears selection when changing tabs', async () => {
        // Select an item
        findFirstTodoItem().vm.$emit(
          'select-change',
          todosResponse.data.currentUser.todos.nodes[0].id,
          true,
        );
        await nextTick();
        expect(findSelectedTodoItems()).toHaveLength(1);

        // Change tab
        findGlTabs().vm.$emit('input', 2);
        await nextTick();

        expect(findSelectedTodoItems()).toHaveLength(0);
      });

      it('updates selected prop when selecting items', async () => {
        const todoId = todosResponse.data.currentUser.todos.nodes[0].id;
        findFirstTodoItem().vm.$emit('select-change', todoId, true);
        await nextTick();

        // Check that exactly one item is selected
        expect(findSelectedTodoItems()).toHaveLength(1);

        // Check that the correct item is selected
        const selectedItem = findTodoItems().at(0); // Since we selected the first item
        expect(selectedItem.props('selected')).toBe(true);
      });

      it('enables "select all" state when all items are selected indivudually', async () => {
        // Select todo items one by one
        const allTodoIds = todosResponse.data.currentUser.todos.nodes.map((todo) => todo.id);
        allTodoIds.forEach((id) => {
          findFirstTodoItem().vm.$emit('select-change', id, true);
        });
        await nextTick();

        expect(findSelectAllCheckbox().attributes('checked')).toBe('true');
      });

      it('clears "select all" state when last item is deselected', async () => {
        // First select all
        findSelectAllCheckbox().vm.$emit('change', true);
        await nextTick();
        expect(findSelectAllCheckbox().attributes('checked')).toBe('true');

        // Then deselect one by one
        for (const todo of todosResponse.data.currentUser.todos.nodes) {
          findFirstTodoItem().vm.$emit('select-change', todo.id, false);
        }
        await nextTick();

        expect(findSelectAllCheckbox().attributes('checked')).toBeUndefined();
      });
    });

    describe('bulk actions', () => {
      it('shows bulk bar when items are selected', async () => {
        expect(findBulkBar().isVisible()).toBe(false);

        findFirstTodoItem().vm.$emit(
          'select-change',
          todosResponse.data.currentUser.todos.nodes[0].id,
          true,
        );
        await nextTick();

        expect(findBulkBar().isVisible()).toBe(true);
      });

      it('clears selection and refreshes after bulk action', async () => {
        findFirstTodoItem().vm.$emit(
          'select-change',
          todosResponse.data.currentUser.todos.nodes[0].id,
          true,
        );
        await nextTick();

        findBulkBar().vm.$emit('change');
        await nextTick();

        expect(findSelectedTodoItems()).toHaveLength(0);
        expect(todosQuerySuccessHandler).toHaveBeenCalled();
      });
    });
  });
});
