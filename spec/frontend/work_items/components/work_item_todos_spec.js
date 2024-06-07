import { GlButton, GlIcon } from '@gitlab/ui';

import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import WorkItemTodos from '~/work_items/components/work_item_todos.vue';
import {
  TODO_DONE_ICON,
  TODO_ADD_ICON,
  TODO_PENDING_STATE,
  TODO_DONE_STATE,
} from '~/work_items/constants';
import { updateGlobalTodoCount } from '~/sidebar/utils';
import createWorkItemTodosMutation from '~/work_items/graphql/create_work_item_todos.mutation.graphql';
import markDoneWorkItemTodosMutation from '~/work_items/graphql/mark_done_work_item_todos.mutation.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';

import { workItemResponseFactory, getTodosMutationResponse } from '../mock_data';

jest.mock('~/sidebar/utils');

describe('WorkItemTodo component', () => {
  Vue.use(VueApollo);

  let wrapper;

  const findTodoWidget = () => wrapper.findComponent(GlButton);
  const findTodoIcon = () => wrapper.findComponent(GlIcon);

  const errorMessage = 'Failed to add item';
  const workItemQueryResponse = workItemResponseFactory({ canUpdate: true });
  const mockWorkItemId = workItemQueryResponse.data.workItem.id;
  const mockWorkItemIid = workItemQueryResponse.data.workItem.iid;
  const mockWorkItemFullpath = workItemQueryResponse.data.workItem.namespace.fullPath;

  const createTodoSuccessHandler = jest
    .fn()
    .mockResolvedValue(getTodosMutationResponse(TODO_PENDING_STATE));
  const markDoneTodoSuccessHandler = jest
    .fn()
    .mockResolvedValue(getTodosMutationResponse(TODO_DONE_STATE));
  const failureHandler = jest.fn().mockRejectedValue(new Error(errorMessage));

  const inputVariablesCreateTodos = {
    targetId: 'gid://gitlab/WorkItem/1',
  };

  const inputVariablesMarkDoneTodos = {
    id: 'gid://gitlab/Todo/1',
  };

  const mockCurrentUserTodos = {
    id: 'gid://gitlab/Todo/1',
  };

  const createComponent = ({
    mutation = createWorkItemTodosMutation,
    currentUserTodosHandler = createTodoSuccessHandler,
    currentUserTodos = [],
  } = {}) => {
    const mockApolloProvider = createMockApollo([[mutation, currentUserTodosHandler]]);

    mockApolloProvider.clients.defaultClient.cache.writeQuery({
      query: workItemByIidQuery,
      variables: { fullPath: mockWorkItemFullpath, iid: mockWorkItemIid },
      data: {
        ...workItemQueryResponse.data,
        workspace: {
          __typename: 'Project',
          id: 'gid://gitlab/Project/1',
          workItem: workItemQueryResponse.data.workItem,
        },
      },
    });

    wrapper = shallowMountExtended(WorkItemTodos, {
      apolloProvider: mockApolloProvider,
      propsData: {
        workItemId: mockWorkItemId,
        workItemIid: mockWorkItemIid,
        workItemFullpath: mockWorkItemFullpath,
        currentUserTodos,
      },
      provide: {
        isGroup: false,
      },
    });
  };

  it('renders the widget', () => {
    createComponent();

    expect(findTodoWidget().exists()).toBe(true);
    expect(findTodoIcon().props('name')).toEqual(TODO_ADD_ICON);
    expect(findTodoIcon().classes('!gl-fill-blue-500')).toBe(false);
  });

  it('renders mark as done button when there is pending item', () => {
    createComponent({
      currentUserTodos: [mockCurrentUserTodos],
    });

    expect(findTodoIcon().props('name')).toEqual(TODO_DONE_ICON);
    expect(findTodoIcon().classes('!gl-fill-blue-500')).toBe(true);
  });

  it.each`
    assertionName  | mutation                         | currentUserTodosHandler       | currentUserTodos          | inputVariables
    ${'create'}    | ${createWorkItemTodosMutation}   | ${createTodoSuccessHandler}   | ${[]}                     | ${inputVariablesCreateTodos}
    ${'mark done'} | ${markDoneWorkItemTodosMutation} | ${markDoneTodoSuccessHandler} | ${[mockCurrentUserTodos]} | ${inputVariablesMarkDoneTodos}
  `(
    'calls $assertionName todos mutation when to do button is toggled',
    async ({ mutation, currentUserTodosHandler, currentUserTodos, inputVariables }) => {
      createComponent({
        mutation,
        currentUserTodosHandler,
        currentUserTodos,
      });

      findTodoWidget().vm.$emit('click');

      await waitForPromises();

      expect(currentUserTodosHandler).toHaveBeenCalledWith({
        input: inputVariables,
      });
      expect(updateGlobalTodoCount).toHaveBeenCalled();
    },
  );

  it('emits error when the update mutation fails', async () => {
    createComponent({
      currentUserTodosHandler: failureHandler,
    });

    findTodoWidget().vm.$emit('click');

    await waitForPromises();

    expect(wrapper.emitted('error')).toEqual([[errorMessage]]);
  });
});
