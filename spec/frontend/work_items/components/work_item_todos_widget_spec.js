import Vue from 'vue';
import VueApollo from 'vue-apollo';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { expectCacheHit } from 'helpers/apollo_cache_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { typePolicies } from '~/lib/graphql';
import possibleTypes from '~/graphql_shared/possible_types.json';
import { config } from '~/graphql_shared/issuable_client';
import { updateGlobalTodoCount } from '~/sidebar/utils';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import workItemCurrentUserTodosQuery from '~/work_items/graphql/work_item_current_user_todos.query.graphql';
import workItemCurrentUserTodosUpdatedSubscription from '~/work_items/graphql/work_item_current_user_todos.subscription.graphql';
import updateWorkItemCurrentUserTodosMutation from '~/work_items/graphql/update_work_item_current_user_todos.mutation.graphql';
import WorkItemTodosWidget from '~/work_items/components/work_item_todos_widget.vue';
import TodosToggle from '~/work_items/components/shared/todos_toggle.vue';
import {
  workItemByIidResponseFactory,
  workItemCurrentUserTodosResponseFactory,
  workItemCurrentUserTodosMutationResponseFactory,
} from 'ee_else_ce_jest/work_items/mock_data';

jest.mock('~/sidebar/utils');

Vue.use(VueApollo);

describe('WorkItemTodosWidget', () => {
  let wrapper;
  let apolloProvider;

  const workItemId = 'gid://gitlab/WorkItem/1';
  const fullPath = 'test-project-path';
  const iid = '1';

  const pendingTodo = { id: 'gid://gitlab/Todo/1', state: 'pending', __typename: 'Todo' };
  const newTodo = { id: 'gid://gitlab/Todo/2', state: 'pending', __typename: 'Todo' };

  const findTodosToggle = () => wrapper.findComponent(TodosToggle);
  const cachedTodoIds = () =>
    findTodosToggle()
      .props('currentUserTodos')
      .map(({ id }) => id);

  const createComponent = ({
    useWorkItemFeatures = false,
    todos = [pendingTodo],
    seedDetailQuery = false,
    mutationHandler = jest
      .fn()
      .mockResolvedValue(
        workItemCurrentUserTodosMutationResponseFactory({ todos: [], useWorkItemFeatures }),
      ),
    queryHandler = jest
      .fn()
      .mockResolvedValue(workItemCurrentUserTodosResponseFactory({ todos, useWorkItemFeatures })),
  } = {}) => {
    apolloProvider = createMockApollo(
      [
        [workItemCurrentUserTodosQuery, queryHandler],
        [
          workItemCurrentUserTodosUpdatedSubscription,
          jest.fn().mockResolvedValue({ data: { workItemUpdated: null } }),
        ],
        [updateWorkItemCurrentUserTodosMutation, mutationHandler],
      ],
      {},
      // The issuable policies are what merge a partial `onlyTypes:` payload into the
      // cached widgets instead of clobbering them.
      {
        typePolicies: { ...typePolicies, ...config.cacheConfig.typePolicies },
        possibleTypes: { ...possibleTypes, ...config.cacheConfig.possibleTypes },
      },
    );

    if (seedDetailQuery) {
      apolloProvider.defaultClient.cache.writeQuery({
        query: workItemByIidQuery,
        variables: { fullPath, iid, useWorkItemFeatures },
        // The WorkItem fragment adds `features` under the flag and keeps `widgets`, so the
        // seed needs both. `features: {}` fills every key from `mockWorkItemFeaturesData`.
        data: workItemByIidResponseFactory(useWorkItemFeatures ? { features: {} } : {}).data,
      });
    }

    wrapper = shallowMountExtended(WorkItemTodosWidget, {
      apolloProvider,
      provide: { glFeatures: { workItemFeaturesField: useWorkItemFeatures } },
      propsData: { workItemId, workItemIid: iid, fullPath },
    });

    return { mutationHandler, queryHandler };
  };

  describe('while the to-do items are loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render the toggle', () => {
      expect(findTodosToggle().exists()).toBe(false);
    });
  });

  describe('when the to-do items have loaded', () => {
    let handlers;

    beforeEach(async () => {
      handlers = createComponent();
      await waitForPromises();
    });

    it('fetches the to-do items and renders the toggle', () => {
      expect(handlers.queryHandler).toHaveBeenCalledTimes(1);
      expect(findTodosToggle().exists()).toBe(true);
    });

    it('subscribes to work item updates so quick actions are reflected', () => {
      expect(cachedTodoIds()).toEqual([pendingTodo.id]);
    });
  });

  describe.each`
    path          | useWorkItemFeatures
    ${'widgets'}  | ${false}
    ${'features'} | ${true}
  `('on the $path path', ({ useWorkItemFeatures }) => {
    const variables = { fullPath, iid, useWorkItemFeatures };

    describe('when there are no pending to-do items', () => {
      let handlers;

      beforeEach(async () => {
        handlers = createComponent({
          useWorkItemFeatures,
          todos: [],
          mutationHandler: jest.fn().mockResolvedValue(
            workItemCurrentUserTodosMutationResponseFactory({
              todos: [newTodo],
              useWorkItemFeatures,
            }),
          ),
        });
        await waitForPromises();

        findTodosToggle().vm.$emit('toggle');
        await waitForPromises();
      });

      it('adds the to-do item', () => {
        expect(handlers.mutationHandler).toHaveBeenCalledWith({
          input: { id: workItemId, currentUserTodosWidget: { action: 'ADD' } },
          useWorkItemFeatures,
        });
      });

      it('reflects the new to-do item with no update hook', () => {
        expect(cachedTodoIds()).toEqual([newTodo.id]);
      });

      it('leaves the to-do items query fully readable from the cache', () => {
        expectCacheHit(apolloProvider.defaultClient.cache, {
          query: workItemCurrentUserTodosQuery,
          variables,
        });
      });

      it('increments the global to-do count', () => {
        expect(updateGlobalTodoCount).toHaveBeenCalledWith(1);
      });
    });

    describe('when there are pending to-do items', () => {
      // More than one, so the count assertion below cannot pass on an off-by-one.
      const seededTodos = [pendingTodo, newTodo];

      let handlers;

      beforeEach(async () => {
        handlers = createComponent({
          useWorkItemFeatures,
          todos: seededTodos,
        });
        await waitForPromises();

        findTodosToggle().vm.$emit('toggle');
        await waitForPromises();
      });

      it('marks them done', () => {
        expect(handlers.mutationHandler).toHaveBeenCalledWith({
          input: { id: workItemId, currentUserTodosWidget: { action: 'MARK_AS_DONE' } },
          useWorkItemFeatures,
        });
      });

      it('clears them with no update hook', () => {
        expect(cachedTodoIds()).toEqual([]);
      });

      it('leaves the to-do items query fully readable from the cache', () => {
        expectCacheHit(apolloProvider.defaultClient.cache, {
          query: workItemCurrentUserTodosQuery,
          variables,
        });
      });

      // The mutation result empties the list, so the count has to be read before awaiting.
      // Reading it afterwards yields -0 and fails here.
      it('decrements the global to-do count by the number marked done', () => {
        expect(updateGlobalTodoCount).toHaveBeenCalledWith(-seededTodos.length);
      });
    });

    // The mutation returns only the to-do widget, so without the by-type merge policy it
    // would replace everything else the detail query had cached.
    describe('when the full work item is already cached', () => {
      const cachedContainers = () => {
        const workItem = apolloProvider.defaultClient.cache.extract()[`WorkItem:${workItemId}`];
        return {
          widgets: workItem.widgets?.map(({ __typename }) => __typename) ?? [],
          features: Object.keys(workItem.features ?? {}),
        };
      };

      let containersBefore;

      beforeEach(async () => {
        createComponent({ useWorkItemFeatures, seedDetailQuery: true });
        await waitForPromises();
        containersBefore = cachedContainers();

        findTodosToggle().vm.$emit('toggle');
        await waitForPromises();
      });

      it('leaves everything else the work item had cached alone', () => {
        expect(cachedContainers()).toEqual(containersBefore);
        expect(
          useWorkItemFeatures ? containersBefore.features : containersBefore.widgets,
        ).not.toHaveLength(0);
      });

      it('leaves the work item query fully readable from the cache', () => {
        expectCacheHit(apolloProvider.defaultClient.cache, {
          query: workItemByIidQuery,
          variables,
        });
      });
    });
  });

  describe('when the mutation returns errors', () => {
    beforeEach(async () => {
      jest.spyOn(Sentry, 'captureException').mockImplementation();
      createComponent({
        mutationHandler: jest.fn().mockResolvedValue({
          data: { workItemUpdate: { workItem: null, errors: ['Something went wrong'] } },
        }),
      });
      await waitForPromises();

      findTodosToggle().vm.$emit('toggle');
      await waitForPromises();
    });

    it('emits an error and reports it', () => {
      expect(wrapper.emitted('error')).toEqual([['Something went wrong']]);
      expect(Sentry.captureException).toHaveBeenCalled();
    });

    it('stops showing the toggle as updating', () => {
      expect(findTodosToggle().props('isUpdating')).toBe(false);
    });
  });

  describe('when the mutation fails', () => {
    beforeEach(async () => {
      jest.spyOn(Sentry, 'captureException').mockImplementation();
      createComponent({
        mutationHandler: jest.fn().mockRejectedValue(new Error('Network error')),
      });
      await waitForPromises();

      findTodosToggle().vm.$emit('toggle');
      await waitForPromises();
    });

    it('emits an error and reports it', () => {
      expect(wrapper.emitted('error')).toEqual([['Network error']]);
      expect(Sentry.captureException).toHaveBeenCalled();
    });
  });

  describe('when the query fails', () => {
    beforeEach(async () => {
      jest.spyOn(Sentry, 'captureException').mockImplementation();
      createComponent({
        queryHandler: jest.fn().mockRejectedValue(new Error('Network error')),
      });
      await waitForPromises();
    });

    it('emits an error and reports it', () => {
      expect(wrapper.emitted('error')).toEqual([
        ['Something went wrong when fetching the to-do state. Please try again.'],
      ]);
      expect(Sentry.captureException).toHaveBeenCalled();
    });
  });
});
