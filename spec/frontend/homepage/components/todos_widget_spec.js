import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import TodosWidget from '~/homepage/components/todos_widget.vue';
import TodoItem from '~/todos/components/todo_item.vue';
import getTodosQuery from '~/todos/components/queries/get_todos.query.graphql';
import { TABS_INDICES } from '~/todos/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import BaseWidget from '~/homepage/components/base_widget.vue';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import {
  EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
  TRACKING_LABEL_TODO_ITEMS,
  TRACKING_PROPERTY_ALL_TODOS,
} from '~/homepage/tracking_constants';
import { todosResponse } from '../../todos/mock_data';

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

  const findFilterDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findTodoItems = () => wrapper.findAllComponents(TodoItem);
  const findFirstTodoItem = () => wrapper.findComponent(TodoItem);
  const findEmptyState = () => wrapper.findByText('All your to-do items are done.');
  const findAllTodosLink = () => wrapper.find('a[href="/dashboard/todos"]');
  const findBaseWidget = () => wrapper.findComponent(BaseWidget);
  const findErrorMessage = () =>
    wrapper.findByText('Your to-do items are not available. Please refresh the page to try again.');

  describe('rendering', () => {
    it('shows a link to all todos', () => {
      createComponent();

      const link = findAllTodosLink();
      expect(link.exists()).toBe(true);
      expect(link.text()).toBe('All to-do items');
      expect(link.attributes('href')).toBe('/dashboard/todos');
    });
  });

  describe('empty state', () => {
    it('shows empty state when there are no todos', async () => {
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

      expect(findEmptyState().exists()).toBe(true);
      expect(findTodoItems()).toHaveLength(0);
    });

    it('does not show empty state when loading', () => {
      createComponent();

      expect(findEmptyState().exists()).toBe(false);
    });

    it('does not show empty state when there are todos', async () => {
      createComponent();
      await waitForPromises();

      expect(findEmptyState().exists()).toBe(false);
      expect(findTodoItems().length).toBeGreaterThan(0);
    });
  });

  describe('GraphQL query', () => {
    it('makes the correct GraphQL query with proper variables', () => {
      createComponent();

      expect(todosQuerySuccessHandler).toHaveBeenCalledWith({
        action: null,
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

    describe('when query fails', () => {
      beforeEach(() => {
        createComponent({ todosQueryHandler: todosQueryErrorHandler });
        return waitForPromises();
      });

      it('captures error with Sentry when query fails', () => {
        expect(Sentry.captureException).toHaveBeenCalledWith(expect.any(Error));
      });

      it('shows an error and hides the filters dropdown when query fails', () => {
        expect(findFilterDropdown().exists()).toBe(false);
        expect(findErrorMessage().exists()).toBe(true);
      });
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

  describe('filter functionality', () => {
    const findFilteredEmptyState = () =>
      wrapper.findByText('Sorry, your filter produced no results');

    it('renders filter dropdown', () => {
      createComponent();

      expect(findFilterDropdown().exists()).toBe(true);
    });

    it('queries without action parameter when no filter is set', () => {
      createComponent();

      expect(todosQuerySuccessHandler).toHaveBeenCalledWith({
        first: 5,
        state: ['pending'],
        action: null,
      });
    });

    it('queries with action parameter when filter is set', async () => {
      createComponent();
      todosQuerySuccessHandler.mockClear();

      await findFilterDropdown().vm.$emit('select', 'assigned');
      await waitForPromises();

      expect(todosQuerySuccessHandler).toHaveBeenCalledWith({
        first: 5,
        state: ['pending'],
        action: ['assigned'],
      });
    });

    it('queries with multiple actions for semicolon-separated filter', async () => {
      createComponent();
      todosQuerySuccessHandler.mockClear();

      await findFilterDropdown().vm.$emit('select', 'mentioned;directly_addressed');
      await waitForPromises();

      expect(todosQuerySuccessHandler).toHaveBeenCalledWith({
        first: 5,
        state: ['pending'],
        action: ['mentioned', 'directly_addressed'],
      });
    });

    it('shows filtered empty state when no todos match filter', async () => {
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

      const queryHandler = jest.fn((value) => {
        // Return an empty response if the filter is provided
        if (value.action) {
          return emptyResponse;
        }
        return todosResponse;
      });
      createComponent({ todosQueryHandler: queryHandler });

      await findFilterDropdown().vm.$emit('select', 'build_failed');
      await waitForPromises();

      expect(findFilteredEmptyState().exists()).toBe(true);
      expect(findEmptyState().exists()).toBe(false);
    });
  });

  describe('refresh functionality', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('refreshes on becoming visible again', async () => {
      const refetchSpy = jest.spyOn(wrapper.vm.$apollo.queries.todos, 'refetch');
      findBaseWidget().vm.$emit('visible');
      await waitForPromises();

      expect(refetchSpy).toHaveBeenCalled();
      refetchSpy.mockRestore();
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

  describe('tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('tracks click on "All to-do items" link', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      const allTodosLink = findAllTodosLink();

      allTodosLink.element.addEventListener('click', (e) => e.preventDefault());
      allTodosLink.trigger('click');

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
        {
          label: TRACKING_LABEL_TODO_ITEMS,
          property: TRACKING_PROPERTY_ALL_TODOS,
        },
        undefined,
      );
    });
  });
});
