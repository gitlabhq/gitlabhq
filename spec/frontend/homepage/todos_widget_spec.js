import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import TodosWidget from '~/homepage/components/todos_widget.vue';
import TodoItem from '~/todos/components/todo_item.vue';
import getTodosQuery from '~/todos/components/queries/get_todos.query.graphql';
import { TABS_INDICES } from '~/todos/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { todosResponse } from '../todos/mock_data';

Vue.use(VueApollo);

jest.mock('~/sentry/sentry_browser_wrapper', () => ({
  captureException: jest.fn(),
}));

describe('TodosWidget', () => {
  let wrapper;

  const todosQuerySuccessHandler = jest.fn().mockResolvedValue(todosResponse);
  const todosQueryErrorHandler = jest.fn().mockRejectedValue(new Error('GraphQL Error'));

  const createComponent = ({ todosQueryHandler = todosQuerySuccessHandler } = {}) => {
    const mockApollo = createMockApollo([[getTodosQuery, todosQueryHandler]]);

    wrapper = shallowMountExtended(TodosWidget, {
      apolloProvider: mockApollo,
    });
  };

  const findTodoItems = () => wrapper.findAllComponents(TodoItem);
  const findFirstTodoItem = () => wrapper.findComponent(TodoItem);
  const findRefreshButton = () => wrapper.findComponent(GlButton);
  const findAllTodosLink = () => wrapper.find('a[href="/dashboard/todos"]');

  describe('rendering', () => {
    it('shows a refresh button with correct props', () => {
      createComponent();

      const refreshButton = findRefreshButton();
      expect(refreshButton.exists()).toBe(true);
      expect(refreshButton.props('icon')).toBe('retry');
    });

    it('shows a link to all todos', () => {
      createComponent();

      const link = findAllTodosLink();
      expect(link.exists()).toBe(true);
      expect(link.text()).toBe('All to-do items');
      expect(link.attributes('href')).toBe('/dashboard/todos');
    });
  });

  describe('loading state', () => {
    it('shows loading state on refresh button while fetching todos', () => {
      createComponent();

      expect(findRefreshButton().props('loading')).toBe(true);
    });

    it('hides loading state after todos are fetched', async () => {
      createComponent();
      await waitForPromises();

      expect(findRefreshButton().props('loading')).toBe(false);
    });
  });

  describe('GraphQL query', () => {
    it('makes the correct GraphQL query with proper variables', () => {
      createComponent();

      expect(todosQuerySuccessHandler).toHaveBeenCalledWith({
        first: 5,
        state: ['pending'],
      });
    });

    it('updates component data when query resolves', async () => {
      createComponent();
      await waitForPromises();

      expect(wrapper.vm.currentUserId).toBe(todosResponse.data.currentUser.id);
      expect(wrapper.vm.todos).toHaveLength(todosResponse.data.currentUser.todos.nodes.length);
    });

    it('handles empty todos response gracefully', async () => {
      const emptyResponse = {
        data: {
          currentUser: {
            id: 'user-1',
            todos: {
              nodes: [],
              pageInfo: {
                hasNextPage: false,
                hasPreviousPage: false,
                startCursor: null,
                endCursor: null,
              },
            },
          },
        },
      };

      const emptyQueryHandler = jest.fn().mockResolvedValue(emptyResponse);
      createComponent({ todosQueryHandler: emptyQueryHandler });
      await waitForPromises();

      expect(wrapper.vm.todos).toEqual([]);
      expect(findTodoItems()).toHaveLength(0);
    });

    it('captures error with Sentry when query fails', async () => {
      createComponent({ todosQueryHandler: todosQueryErrorHandler });
      await waitForPromises();

      expect(Sentry.captureException).toHaveBeenCalledWith(expect.any(Error));
    });
  });

  describe('todo items', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders the correct number of todo items', () => {
      expect(findTodoItems()).toHaveLength(todosResponse.data.currentUser.todos.nodes.length);
    });

    it('passes the correct props to todo items', () => {
      expect(findFirstTodoItem().props('todo')).toEqual(
        todosResponse.data.currentUser.todos.nodes[0],
      );
    });

    it('refetches todos when a todo item changes', async () => {
      // Reset call count after initial query
      todosQuerySuccessHandler.mockClear();

      const firstTodoItem = findFirstTodoItem();
      expect(firstTodoItem.exists()).toBe(true);

      firstTodoItem.vm.$emit('change');
      await waitForPromises();

      expect(todosQuerySuccessHandler).toHaveBeenCalledTimes(1);
    });
  });

  describe('refresh functionality', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('refetches todos when refresh button is clicked', async () => {
      todosQuerySuccessHandler.mockClear();

      await findRefreshButton().vm.$emit('click');
      await waitForPromises();

      expect(todosQuerySuccessHandler).toHaveBeenCalledTimes(1);
    });

    it('shows loading state during refresh', async () => {
      const refreshButton = findRefreshButton();

      await waitForPromises();
      expect(refreshButton.props('loading')).toBe(false);

      refreshButton.vm.$emit('click');
      await nextTick();
      expect(refreshButton.props('loading')).toBe(true);

      await waitForPromises();
      expect(refreshButton.props('loading')).toBe(false);
    });
  });

  describe('provide/inject', () => {
    it('provides the correct values to child components', () => {
      createComponent();

      const provided = wrapper.vm.$options.provide.call(wrapper.vm);

      expect(provided.currentTab).toBe(TABS_INDICES.pending);
      expect(provided.currentTime).toBeInstanceOf(Date);
      expect(provided.currentUserId).toBeDefined();
    });

    it('provides reactive currentUserId after query resolves', async () => {
      createComponent();

      const provided = wrapper.vm.$options.provide.call(wrapper.vm);
      expect(provided.currentUserId.value).toBeNull();

      await waitForPromises();

      expect(provided.currentUserId.value).toBe(todosResponse.data.currentUser.id);
    });
  });
});
