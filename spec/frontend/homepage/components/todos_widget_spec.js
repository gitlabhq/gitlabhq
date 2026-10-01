import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlSkeletonLoader, GlTab, GlTabs } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import { useConfigurePathHelpers } from 'helpers/configure_path_helpers';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import TodosWidget from '~/homepage/components/todos_widget.vue';
import TodoItem from '~/todos/components/todo_item.vue';
import getTodosQuery from '~/todos/components/queries/get_todos.query.graphql';
import getTodosCountsQuery from '~/homepage/graphql/queries/todos_widget_counts.query.graphql';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import BaseWidget from '~/homepage/components/base_widget.vue';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import {
  EVENT_FILTER_TODOS_ON_HOMEPAGE,
  EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
  TRACKING_LABEL_TODO_ITEMS,
  TRACKING_PROPERTY_ALL_TODOS,
} from '~/homepage/tracking_constants';
import { todosResponse } from '../../todos/mock_data';

Vue.use(VueApollo);

jest.mock('~/sentry/sentry_browser_wrapper', () => ({
  captureException: jest.fn(),
}));

const todoCount = (count) => ({ count, __typename: 'TodoConnection' });

const countsResponse = {
  data: {
    currentUser: {
      id: 'gid://gitlab/User/1',
      reviewRequested: todoCount(1),
      assigned: todoCount(6),
      buildFailed: todoCount(0),
      unmergeable: todoCount(0),
      reviewSubmitted: todoCount(2),
      __typename: 'CurrentUser',
    },
  },
};

const emptyTodosResponse = {
  data: {
    currentUser: {
      id: 'gid://gitlab/User/1',
      todos: {
        nodes: [],
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: null,
          endCursor: null,
          __typename: 'PageInfo',
        },
        __typename: 'TodoConnection',
      },
      __typename: 'CurrentUser',
    },
  },
};

// Indices into FILTER_OPTIONS, which drives both the tab order and the query.
const TAB_REVIEW_REQUESTED = 1;
const TAB_ASSIGNED = 2;
const TAB_BUILD_FAILED = 3;

describe('TodosWidget', () => {
  let wrapper;

  const todosQuerySuccessHandler = jest.fn().mockResolvedValue(todosResponse);
  const todosQueryErrorHandler = jest.fn().mockRejectedValue(new Error('GraphQL Error'));
  const countsQuerySuccessHandler = jest.fn().mockResolvedValue(countsResponse);

  const createComponent = ({
    todosQueryHandler = todosQuerySuccessHandler,
    countsQueryHandler = countsQuerySuccessHandler,
  } = {}) => {
    const mockApollo = createMockApollo([
      [getTodosQuery, todosQueryHandler],
      [getTodosCountsQuery, countsQueryHandler],
    ]);

    // Tabs are mounted for real so `lazy` renders only the active panel, which
    // is what makes an empty tabpanel detectable here.
    wrapper = mountExtended(TodosWidget, {
      apolloProvider: mockApollo,
      stubs: {
        TodoItem: stubComponent(TodoItem),
      },
    });
  };

  const findTabs = () => wrapper.findComponent(GlTabs);
  const findTabCounts = () => wrapper.findAllByTestId('tab-count');
  const findTodoItems = () => wrapper.findAllComponents(TodoItem);
  const findFirstTodoItem = () => wrapper.findComponent(TodoItem);
  const findEmptyState = () => wrapper.findByText('All your to-do items are done.');
  const findAllTodosLink = () => wrapper.findByText('All to-do items');
  const findBaseWidget = () => wrapper.findComponent(BaseWidget);
  const findErrorMessage = () =>
    wrapper.findByText('Your to-do items are not available. Please refresh the page to try again.');

  const selectTab = (index) => findTabs().vm.$emit('input', index);

  describe('rendering', () => {
    it('shows a link to all todos', () => {
      createComponent();

      const link = findAllTodosLink();
      expect(link.exists()).toBe(true);
      expect(link.text()).toBe('All to-do items');
      expect(link.attributes('href')).toBe('/dashboard/todos');
    });

    it('renders a tab per filter option', () => {
      createComponent();

      expect(wrapper.findAllComponents(GlTab)).toHaveLength(6);
    });
  });

  describe('tab panels', () => {
    const findActiveTab = () => wrapper.find('.gl-tab-nav-item-active');
    const findActivePanel = () => wrapper.find(`#${findActiveTab().attributes('aria-controls')}`);
    const findPopulatedPanels = () =>
      wrapper
        .findAll('[role="tabpanel"]')
        .wrappers.filter((panel) => panel.findAllComponents(TodoItem).length > 0);

    it('renders the list inside the panel the active tab controls', async () => {
      createComponent();
      await waitForPromises();

      expect(findActivePanel().attributes('role')).toBe('tabpanel');
      expect(findActivePanel().findAllComponents(TodoItem).length).toBeGreaterThan(0);
    });

    it('only renders content for the active tab', async () => {
      createComponent();
      await waitForPromises();

      expect(findPopulatedPanels()).toHaveLength(1);
    });

    it('moves the list into the newly selected tab panel', async () => {
      createComponent();
      await waitForPromises();

      // Click the real tab rather than emitting, so BTabs drives the activation.
      await wrapper.findAll('.gl-tab-nav-item').at(TAB_ASSIGNED).trigger('click');
      await waitForPromises();

      expect(findActiveTab().text()).toContain('Assigned');
      expect(findActivePanel().findAllComponents(TodoItem).length).toBeGreaterThan(0);
      expect(findPopulatedPanels()).toHaveLength(1);
    });
  });

  describe('empty state', () => {
    it('shows empty state when there are no todos', async () => {
      createComponent({ todosQueryHandler: jest.fn().mockResolvedValue(emptyTodosResponse) });
      await waitForPromises();

      expect(findEmptyState().exists()).toBe(true);
      expect(findTodoItems()).toHaveLength(0);
    });

    describe('when the query resolves without a current user', () => {
      beforeEach(async () => {
        const nullUserHandler = jest.fn().mockResolvedValue({ data: { currentUser: null } });
        createComponent({ todosQueryHandler: nullUserHandler });
        await waitForPromises();
        // An exception thrown inside the Apollo `update` hook is rethrown from a timer
        jest.runOnlyPendingTimers();
      });

      it('shows the empty state', () => {
        expect(findEmptyState().exists()).toBe(true);
        expect(findTodoItems()).toHaveLength(0);
        expect(findErrorMessage().exists()).toBe(false);
      });
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
        first: 15,
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
      createComponent({ todosQueryHandler: jest.fn().mockResolvedValue(emptyTodosResponse) });
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

      it('shows an error and hides the tabs when query fails', () => {
        expect(findTabs().exists()).toBe(false);
        expect(findErrorMessage().exists()).toBe(true);
      });
    });
  });

  describe('tab counts', () => {
    it('renders no badges until the counts resolve', () => {
      createComponent();

      expect(findTabCounts()).toHaveLength(0);
    });

    it('renders a badge per reason tab, capped at 5+, and none on All', async () => {
      createComponent();
      await waitForPromises();

      expect(findTabCounts().wrappers.map((badge) => badge.text())).toEqual([
        '1',
        '5+',
        '0',
        '0',
        '2',
      ]);
    });

    it('describes exact counts to screen readers', async () => {
      createComponent();
      await waitForPromises();

      expect(wrapper.text()).toContain('1 to-do item');
      expect(wrapper.text()).toContain('0 to-do items');
    });

    it('does not read the sentinel value aloud for a capped count', async () => {
      createComponent();
      await waitForPromises();

      // The limited count returns 6, which must not surface as "6 to-do items".
      expect(wrapper.text()).toContain('More than 5 to-do items');
      expect(wrapper.text()).not.toContain('6 to-do items');
    });

    it('asks the backend to stop counting at the badge cap', () => {
      createComponent();

      expect(countsQuerySuccessHandler).toHaveBeenCalledWith({ limit: 5 });
    });

    it('keeps the list usable when only the counts query fails', async () => {
      createComponent({
        countsQueryHandler: jest.fn().mockRejectedValue(new Error('GraphQL Error')),
      });
      await waitForPromises();

      expect(Sentry.captureException).toHaveBeenCalledWith(expect.any(Error));
      expect(findTabCounts()).toHaveLength(0);
      expect(findErrorMessage().exists()).toBe(false);
      expect(findTodoItems().length).toBeGreaterThan(0);
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

    it('refetches todos and counts when a todo item changes', async () => {
      todosQuerySuccessHandler.mockClear();
      countsQuerySuccessHandler.mockClear();

      const firstTodoItem = findFirstTodoItem();
      expect(firstTodoItem.exists()).toBe(true);

      firstTodoItem.vm.$emit('change');
      await waitForPromises();

      expect(todosQuerySuccessHandler).toHaveBeenCalledTimes(1);
      expect(countsQuerySuccessHandler).toHaveBeenCalledTimes(1);
    });
  });

  describe('filter functionality', () => {
    const findFilteredEmptyState = () =>
      wrapper.findByText('Sorry, your filter produced no results');

    it('queries without action parameter when no filter is set', () => {
      createComponent();

      expect(todosQuerySuccessHandler).toHaveBeenCalledWith({
        first: 15,
        state: ['pending'],
        action: null,
      });
    });

    it('queries with action parameter when a tab is selected', async () => {
      createComponent();
      todosQuerySuccessHandler.mockClear();

      await selectTab(TAB_ASSIGNED);
      await waitForPromises();

      expect(todosQuerySuccessHandler).toHaveBeenCalledWith({
        first: 15,
        state: ['pending'],
        action: ['assigned'],
      });
    });

    it('queries with the review_submitted action for the last tab', async () => {
      createComponent();
      todosQuerySuccessHandler.mockClear();

      await selectTab(5);
      await waitForPromises();

      expect(todosQuerySuccessHandler).toHaveBeenCalledWith({
        first: 15,
        state: ['pending'],
        action: ['review_submitted'],
      });
    });

    it('shows the skeleton instead of the previous tab items while switching', async () => {
      createComponent();
      await waitForPromises();
      expect(findTodoItems().length).toBeGreaterThan(0);

      await selectTab(TAB_BUILD_FAILED);

      expect(findTodoItems()).toHaveLength(0);
      expect(wrapper.findAllComponents(GlSkeletonLoader).length).toBeGreaterThan(0);
    });

    it('ignores a negative tab index', async () => {
      createComponent();
      await waitForPromises();
      todosQuerySuccessHandler.mockClear();

      await selectTab(-1);

      expect(wrapper.vm.activeTabIndex).toBe(0);
      expect(todosQuerySuccessHandler).not.toHaveBeenCalled();
    });

    it('shows filtered empty state when no todos match filter', async () => {
      const queryHandler = jest.fn((variables) =>
        variables.action ? emptyTodosResponse : todosResponse,
      );
      createComponent({ todosQueryHandler: queryHandler });
      await waitForPromises();

      await selectTab(TAB_BUILD_FAILED);
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
      const todosRefetchSpy = jest.spyOn(wrapper.vm.$apollo.queries.todos, 'refetch');
      const countsRefetchSpy = jest.spyOn(wrapper.vm.$apollo.queries.counts, 'refetch');
      findBaseWidget().vm.$emit('visible');
      await waitForPromises();

      expect(todosRefetchSpy).toHaveBeenCalled();
      expect(countsRefetchSpy).toHaveBeenCalled();
      todosRefetchSpy.mockRestore();
      countsRefetchSpy.mockRestore();
    });
  });

  describe('provide/inject', () => {
    it('provides the correct values to child components', () => {
      createComponent();

      const provided = wrapper.vm.$options.provide.call(wrapper.vm);

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

  describe('display behavior', () => {
    it('displays only first 5 todos when more than 5 are fetched', async () => {
      const manyTodosResponse = {
        ...todosResponse,
        data: {
          ...todosResponse.data,
          currentUser: {
            ...todosResponse.data.currentUser,
            todos: {
              ...todosResponse.data.currentUser.todos,
              nodes: Array.from({ length: 8 }, (_, i) => ({
                ...todosResponse.data.currentUser.todos.nodes[0],
                id: `gid://gitlab/Todo/${i + 1}`,
                targetUrl: `http://example.com/issue/${i + 1}`,
              })),
            },
          },
        },
      };

      const manyTodosQueryHandler = jest.fn().mockResolvedValue(manyTodosResponse);
      createComponent({ todosQueryHandler: manyTodosQueryHandler });
      await waitForPromises();

      expect(manyTodosQueryHandler).toHaveBeenCalledWith({
        first: 15,
        state: ['pending'],
        action: null,
      });

      expect(wrapper.vm.todos).toHaveLength(8);
      expect(findTodoItems()).toHaveLength(5);
      expect(wrapper.vm.displayedTodos).toHaveLength(5);
      expect(wrapper.vm.displayedTodos[0].id).toBe('gid://gitlab/Todo/1');
      expect(wrapper.vm.displayedTodos[4].id).toBe('gid://gitlab/Todo/5');
    });

    it('displays all todos when fewer than 5 are available', async () => {
      const fewTodosResponse = {
        ...todosResponse,
        data: {
          ...todosResponse.data,
          currentUser: {
            ...todosResponse.data.currentUser,
            todos: {
              ...todosResponse.data.currentUser.todos,
              nodes: Array.from({ length: 3 }, (_, i) => ({
                ...todosResponse.data.currentUser.todos.nodes[0],
                id: `gid://gitlab/Todo/${i + 1}`,
                targetUrl: `http://example.com/issue/${i + 1}`,
              })),
            },
          },
        },
      };

      const fewTodosQueryHandler = jest.fn().mockResolvedValue(fewTodosResponse);
      createComponent({ todosQueryHandler: fewTodosQueryHandler });
      await waitForPromises();

      expect(wrapper.vm.todos).toHaveLength(3);
      expect(findTodoItems()).toHaveLength(3);
      expect(wrapper.vm.displayedTodos).toHaveLength(3);
    });

    it('handles SAML-blocked todos correctly when mixed with accessible todos', async () => {
      const mixedTodosResponse = {
        ...todosResponse,
        data: {
          ...todosResponse.data,
          currentUser: {
            ...todosResponse.data.currentUser,
            todos: {
              ...todosResponse.data.currentUser.todos,
              nodes: [
                {
                  ...todosResponse.data.currentUser.todos.nodes[0],
                  id: 'gid://gitlab/Todo/1',
                },
                {
                  ...todosResponse.data.currentUser.todos.nodes[0],
                  id: 'gid://gitlab/Todo/2',
                  targetUrl: 'http://example.com/saml-auth-url',
                  targetEntity: null,
                  project: null,
                },
                {
                  ...todosResponse.data.currentUser.todos.nodes[1],
                  id: 'gid://gitlab/Todo/3',
                },
              ],
              pageInfo: {
                ...todosResponse.data.currentUser.todos.pageInfo,
                hasNextPage: true,
              },
            },
          },
        },
      };

      const mixedTodosQueryHandler = jest.fn().mockResolvedValue(mixedTodosResponse);
      createComponent({ todosQueryHandler: mixedTodosQueryHandler });
      await waitForPromises();

      expect(findTodoItems()).toHaveLength(3);

      const todoItems = findTodoItems();
      expect(todoItems.at(0).props('todo').targetEntity).not.toBeNull();
      expect(todoItems.at(1).props('todo').targetEntity).toBeNull();
      expect(todoItems.at(2).props('todo').targetEntity).not.toBeNull();
      expect(todoItems.at(1).props('todo').targetUrl).toBe('http://example.com/saml-auth-url');
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

    it('does not track the initial tab, which GlTabs emits on mount', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      selectTab(0);

      expect(trackEventSpy).not.toHaveBeenCalledWith(
        EVENT_FILTER_TODOS_ON_HOMEPAGE,
        expect.anything(),
        undefined,
      );
    });

    it.each`
      tabIndex | expectedValue
      ${1}     | ${'review_requested'}
      ${2}     | ${'assigned'}
      ${3}     | ${'build_failed'}
      ${4}     | ${'unmergeable'}
      ${5}     | ${'review_submitted'}
    `('tracks selecting the $expectedValue tab', ({ tabIndex, expectedValue }) => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      selectTab(tabIndex);

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_FILTER_TODOS_ON_HOMEPAGE,
        { property: expectedValue },
        undefined,
      );
    });

    it('tracks returning to the everything tab', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      await selectTab(TAB_REVIEW_REQUESTED);
      selectTab(0);

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_FILTER_TODOS_ON_HOMEPAGE,
        { property: 'everything' },
        undefined,
      );
    });
  });

  describe('relative URL handling', () => {
    describe('when relative URL root is set', () => {
      useConfigurePathHelpers('/gitlab');

      it('prepends gon.relative_url_root to the todos link', async () => {
        createComponent();
        await waitForPromises();

        expect(findAllTodosLink().attributes('href')).toBe('/gitlab/dashboard/todos');
      });
    });

    describe('when relative URL root is empty', () => {
      useConfigurePathHelpers('');

      it('does not append relative URL root', async () => {
        createComponent();
        await waitForPromises();

        expect(findAllTodosLink().attributes('href')).toBe('/dashboard/todos');
      });
    });

    it('uses dashboard path when gon.relative_url_root is undefined', async () => {
      createComponent();
      await waitForPromises();

      expect(findAllTodosLink().attributes('href')).toBe('/dashboard/todos');
    });
  });
});
