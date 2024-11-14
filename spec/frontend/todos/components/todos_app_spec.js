import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlTabs } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import TodosApp from '~/todos/components/todos_app.vue';
import TodoItem from '~/todos/components/todo_item.vue';
import TodosFilterBar from '~/todos/components/todos_filter_bar.vue';
import TodosMarkAllDoneButton from '~/todos/components/todos_mark_all_done_button.vue';
import getTodosQuery from '~/todos/components/queries/get_todos.query.graphql';
import { INSTRUMENT_TAB_LABELS, STATUS_BY_TAB } from '~/todos/constants';
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
  } = {}) => {
    const mockApollo = createMockApollo();
    mockApollo.defaultClient.setRequestHandler(getTodosQuery, todosQueryHandler);
    mockApollo.defaultClient.setRequestHandler(getPendingTodosCount, todosCountsQueryHandler);

    wrapper = shallowMountExtended(TodosApp, {
      apolloProvider: mockApollo,
    });
  };

  const findTodoItems = () => wrapper.findAllComponents(TodoItem);
  const findGlTabs = () => wrapper.findComponent(GlTabs);
  const findFilterBar = () => wrapper.findComponent(TodosFilterBar);
  const findMarkAllDoneButton = () => wrapper.findComponent(TodosMarkAllDoneButton);
  const findRefreshButton = () => wrapper.findByTestId('refresh-todos');
  const findPendingTodosCount = () => wrapper.findByTestId('pending-todos-count');

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

  it('passes the default status to the filter bar', () => {
    createComponent();

    expect(findFilterBar().props('todosStatus')).toEqual(['pending']);
  });

  it.each`
    tabIndex | status                 | label
    ${0}     | ${['pending']}         | ${'status_pending'}
    ${1}     | ${['done']}            | ${'status_done'}
    ${2}     | ${['pending', 'done']} | ${'status_all'}
  `('updates the filter bar status when the tab changes', async ({ tabIndex, status, label }) => {
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
  });
});
