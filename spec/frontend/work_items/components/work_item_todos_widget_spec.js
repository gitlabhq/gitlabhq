import Vue from 'vue';
import VueApollo from 'vue-apollo';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import workItemCurrentUserTodosQuery from '~/work_items/graphql/work_item_current_user_todos.query.graphql';
import workItemCurrentUserTodosUpdatedSubscription from '~/work_items/graphql/work_item_current_user_todos.subscription.graphql';
import WorkItemTodosWidget from '~/work_items/components/work_item_todos_widget.vue';
import TodosToggle from '~/work_items/components/shared/todos_toggle.vue';
import { workItemCurrentUserTodosResponseFactory } from 'ee_else_ce_jest/work_items/mock_data';

Vue.use(VueApollo);

describe('WorkItemTodosWidget', () => {
  let wrapper;

  const todosQueryHandler = jest.fn().mockResolvedValue(workItemCurrentUserTodosResponseFactory());
  const todosSubscriptionHandler = jest.fn().mockResolvedValue({ data: { workItemUpdated: null } });

  const findTodosToggle = () => wrapper.findComponent(TodosToggle);

  const createComponent = () => {
    wrapper = shallowMountExtended(WorkItemTodosWidget, {
      apolloProvider: createMockApollo([
        [workItemCurrentUserTodosQuery, todosQueryHandler],
        [workItemCurrentUserTodosUpdatedSubscription, todosSubscriptionHandler],
      ]),
      propsData: {
        workItemId: 'gid://gitlab/WorkItem/1',
        workItemIid: '1',
        fullPath: 'test-project-path',
      },
    });
  };

  describe('while the to-do items are loading', () => {
    beforeEach(() => {
      createComponent();
    });

    // TodosToggle reads its label once on creation, so rendering it early leaves it stuck.
    it('does not render the toggle', () => {
      expect(findTodosToggle().exists()).toBe(false);
    });
  });

  describe('when the to-do items have loaded', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('fetches the to-do items and renders the toggle', () => {
      expect(todosQueryHandler).toHaveBeenCalledTimes(1);
      expect(findTodosToggle().exists()).toBe(true);
    });

    it('subscribes to work item updates so quick actions are reflected', () => {
      expect(todosSubscriptionHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/WorkItem/1',
        useWorkItemFeatures: false,
      });
    });

    it('passes the pending to-do items to the toggle', () => {
      expect(findTodosToggle().props('currentUserTodos')).toEqual([
        expect.objectContaining({ id: 'gid://gitlab/Todo/1' }),
      ]);
    });
  });

  describe('when the query fails', () => {
    beforeEach(async () => {
      jest.spyOn(Sentry, 'captureException').mockImplementation();
      todosQueryHandler.mockRejectedValueOnce(new Error('Network error'));
      createComponent();
      await waitForPromises();
    });

    it('reports the failure to Sentry', () => {
      expect(Sentry.captureException).toHaveBeenCalledWith(expect.any(Error));
    });

    it('emits an error so the page can surface it', () => {
      expect(wrapper.emitted('error')).toEqual([
        ['Something went wrong when fetching the to-do state. Please try again.'],
      ]);
    });
  });
});
