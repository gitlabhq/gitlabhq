import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlTabs } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import TodosApp from '~/todos/components/todos_app.vue';
import TodoItem from '~/todos/components/todo_item.vue';
import TodosFilterBar from '~/todos/components/todos_filter_bar.vue';
import getTodosQuery from '~/todos/components/queries/get_todos.query.graphql';
import getTodosCountQuery from '~/todos/components/queries/get_todos_count.query.graphql';
import { todosResponse, todosCountsResponse } from '../mock_data';

Vue.use(VueApollo);

describe('TodosApp', () => {
  let wrapper;

  const todosQuerySuccessHandler = jest.fn().mockResolvedValue(todosResponse);
  const todosCountsQuerySuccessHandler = jest.fn().mockResolvedValue(todosCountsResponse);

  const createComponent = ({
    todosQueryHandler = todosQuerySuccessHandler,
    todosCountsQueryHandler = todosCountsQuerySuccessHandler,
  } = {}) => {
    const mockApollo = createMockApollo();
    mockApollo.defaultClient.setRequestHandler(getTodosQuery, todosQueryHandler);
    mockApollo.defaultClient.setRequestHandler(getTodosCountQuery, todosCountsQueryHandler);

    wrapper = shallowMount(TodosApp, {
      apolloProvider: mockApollo,
    });
  };

  const findTodoItems = () => wrapper.findAllComponents(TodoItem);
  const findGlTabs = () => wrapper.findComponent(GlTabs);
  const findFilterBar = () => wrapper.findComponent(TodosFilterBar);

  beforeEach(() => {
    createComponent();
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

  it('passes the default status to the filter bar', () => {
    createComponent();

    expect(findFilterBar().props('todosStatus')).toEqual(['pending']);
  });

  it.each`
    tabIndex | status
    ${1}     | ${['done']}
    ${2}     | ${['pending', 'done']}
  `('updates the filter bar status when the tab changes', async ({ tabIndex, status }) => {
    createComponent();
    findGlTabs().vm.$emit('input', tabIndex);
    await nextTick();

    expect(findFilterBar().props('todosStatus')).toEqual(status);
  });
});
