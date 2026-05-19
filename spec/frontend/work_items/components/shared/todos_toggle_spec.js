import { GlButton, GlAnimatedTodoIcon } from '@gitlab/ui';

import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import TodosToggle from '~/work_items/components/shared/todos_toggle.vue';
import { TODO_DONE_ICON, TODO_ADD_ICON, TODO_PENDING_STATE } from '~/work_items/constants';
import { updateGlobalTodoCount } from '~/sidebar/utils';
import createWorkItemTodosMutation from '~/work_items/graphql/create_work_item_todos.mutation.graphql';
import updateWorkItemCurrentUserTodosMutation from '~/work_items/graphql/update_work_item_current_user_todos.mutation.graphql';

import {
  workItemResponseFactory,
  getTodosMutationResponse,
  getMarkAllDoneTodosMutationResponse,
} from '../../mock_data';

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
  const markAllDoneTodoSuccessHandler = jest
    .fn()
    .mockResolvedValue(getMarkAllDoneTodosMutationResponse());
  const failureHandler = jest.fn().mockRejectedValue(new Error(errorMessage));

  const inputVariablesCreateTodos = {
    targetId: 'gid://gitlab/WorkItem/1',
  };

  const inputVariablesMarkAllDoneTodos = {
    id: 'gid://gitlab/WorkItem/1',
    currentUserTodosWidget: {
      action: 'MARK_AS_DONE',
    },
  };

  const mockCurrentUserTodos = {
    id: 'gid://gitlab/Todo/1',
  };

  const mockMultipleCurrentUserTodos = [
    { id: 'gid://gitlab/Todo/1' },
    { id: 'gid://gitlab/Todo/2' },
    { id: 'gid://gitlab/Todo/3' },
  ];

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
    expect(findAnimatedTodoIcon().classes('!gl-text-status-info')).toBe(false);
    expect(findTodoWidget().props('category')).toBe('tertiary');
  });

  it('renders mark to-do items done button when there is pending item', () => {
    createComponent({
      currentUserTodos: [mockCurrentUserTodos],
    });

    expect(findAnimatedTodoIcon().attributes('name')).toEqual(TODO_DONE_ICON);
    expect(findAnimatedTodoIcon().props('isOn')).toBe(true);
    expect(findAnimatedTodoIcon().classes('!gl-text-status-info')).toBe(true);
  });

  it('calls create todos mutation when to do button is toggled and no pending todos', async () => {
    createComponent({
      mutation: createWorkItemTodosMutation,
      currentUserTodosHandler: createTodoSuccessHandler,
      currentUserTodos: [],
    });

    findTodoWidget().vm.$emit('click');

    await waitForPromises();

    expect(createTodoSuccessHandler).toHaveBeenCalledWith({
      input: inputVariablesCreateTodos,
    });
    expect(wrapper.emitted('todosUpdated')[0][0]).toMatchObject({
      cache: expect.anything(),
      todos: [{ id: expect.anything() }],
    });
    expect(updateGlobalTodoCount).toHaveBeenCalledWith(1);
  });

  it('calls mark all done mutation when to do button is toggled and has pending todo', async () => {
    const mockApolloProvider = createMockApollo([
      [createWorkItemTodosMutation, createTodoSuccessHandler],
      [updateWorkItemCurrentUserTodosMutation, markAllDoneTodoSuccessHandler],
    ]);

    wrapper = shallowMountExtended(TodosToggle, {
      apolloProvider: mockApolloProvider,
      propsData: {
        itemId: mockWorkItemId,
        currentUserTodos: [mockCurrentUserTodos],
        todosButtonType: 'tertiary',
      },
      stubs: {
        GlAnimatedTodoIcon,
      },
    });

    findTodoWidget().vm.$emit('click');

    await waitForPromises();

    expect(markAllDoneTodoSuccessHandler).toHaveBeenCalledWith({
      input: inputVariablesMarkAllDoneTodos,
    });
    expect(wrapper.emitted('todosUpdated')[0][0]).toMatchObject({
      cache: expect.anything(),
      todos: [],
    });
    expect(updateGlobalTodoCount).toHaveBeenCalledWith(-1);
  });

  it('decrements global todo count by correct amount when marking multiple todos done', async () => {
    const mockApolloProvider = createMockApollo([
      [createWorkItemTodosMutation, createTodoSuccessHandler],
      [updateWorkItemCurrentUserTodosMutation, markAllDoneTodoSuccessHandler],
    ]);

    wrapper = shallowMountExtended(TodosToggle, {
      apolloProvider: mockApolloProvider,
      propsData: {
        itemId: mockWorkItemId,
        currentUserTodos: mockMultipleCurrentUserTodos,
        todosButtonType: 'tertiary',
      },
      stubs: {
        GlAnimatedTodoIcon,
      },
    });

    findTodoWidget().vm.$emit('click');

    await waitForPromises();

    expect(markAllDoneTodoSuccessHandler).toHaveBeenCalledWith({
      input: inputVariablesMarkAllDoneTodos,
    });
    expect(updateGlobalTodoCount).toHaveBeenCalledWith(-3);
  });

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
