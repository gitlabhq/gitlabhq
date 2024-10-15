import { GlButton, GlAnimatedTodoIcon } from '@gitlab/ui';

import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import TodosToggle from '~/work_items/components/shared/todos_toggle.vue';
import {
  TODO_DONE_ICON,
  TODO_ADD_ICON,
  TODO_PENDING_STATE,
  TODO_DONE_STATE,
} from '~/work_items/constants';
import { updateGlobalTodoCount } from '~/sidebar/utils';
import createWorkItemTodosMutation from '~/work_items/graphql/create_work_item_todos.mutation.graphql';
import markDoneWorkItemTodosMutation from '~/work_items/graphql/mark_done_work_item_todos.mutation.graphql';

import { workItemResponseFactory, getTodosMutationResponse } from '../../mock_data';

jest.mock('~/sidebar/utils');

describe('WorkItemTodo component', () => {
  Vue.use(VueApollo);

  let wrapper;

  const findTodoWidget = () => wrapper.findComponent(GlButton);
  const findAnimatedTodoIcon = () => wrapper.findComponent(GlAnimatedTodoIcon);

  const errorMessage = 'Failed to add item';
  const workItemQueryResponse = workItemResponseFactory({ canUpdate: true });
  const mockWorkItemId = workItemQueryResponse.data.workItem.id;

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
    todosButtonType = 'tertiary',
  } = {}) => {
    const mockApolloProvider = createMockApollo([[mutation, currentUserTodosHandler]]);

    wrapper = shallowMountExtended(TodosToggle, {
      apolloProvider: mockApolloProvider,
      propsData: {
        itemId: mockWorkItemId,
        currentUserTodos,
        todosButtonType,
      },
      stubs: {
        GlAnimatedTodoIcon,
      },
    });
  };

  it('renders the widget', () => {
    createComponent();

    expect(findTodoWidget().exists()).toBe(true);
    expect(findAnimatedTodoIcon().attributes('name')).toEqual(TODO_ADD_ICON);
    expect(findAnimatedTodoIcon().props('isOn')).toBe(false);
    expect(findAnimatedTodoIcon().classes('!gl-text-blue-500')).toBe(false);
    expect(findTodoWidget().props('category')).toBe('tertiary');
  });

  it('renders mark as done button when there is pending item', () => {
    createComponent({
      currentUserTodos: [mockCurrentUserTodos],
    });

    expect(findAnimatedTodoIcon().attributes('name')).toEqual(TODO_DONE_ICON);
    expect(findAnimatedTodoIcon().props('isOn')).toBe(true);
    expect(findAnimatedTodoIcon().classes('!gl-text-blue-500')).toBe(true);
  });

  it.each`
    assertionName  | mutation                         | currentUserTodosHandler       | currentUserTodos          | inputVariables                 | todos
    ${'create'}    | ${createWorkItemTodosMutation}   | ${createTodoSuccessHandler}   | ${[]}                     | ${inputVariablesCreateTodos}   | ${[{ id: expect.anything() }]}
    ${'mark done'} | ${markDoneWorkItemTodosMutation} | ${markDoneTodoSuccessHandler} | ${[mockCurrentUserTodos]} | ${inputVariablesMarkDoneTodos} | ${[]}
  `(
    'calls $assertionName todos mutation when to do button is toggled',
    async ({ mutation, currentUserTodosHandler, currentUserTodos, inputVariables, todos }) => {
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
      expect(wrapper.emitted('todosUpdated')[0][0]).toMatchObject({
        cache: expect.anything(),
        todos,
      });
      expect(updateGlobalTodoCount).toHaveBeenCalled();
    },
  );

  it('renders secondary button when `todosButtonType` is secondary', () => {
    createComponent({
      todosButtonType: 'secondary',
    });

    expect(findTodoWidget().props('category')).toBe('secondary');
  });

  it('emits error when the update mutation fails', async () => {
    createComponent({
      currentUserTodosHandler: failureHandler,
    });

    findTodoWidget().vm.$emit('click');

    await waitForPromises();

    expect(wrapper.emitted('error')).toEqual([[errorMessage]]);
  });
});
