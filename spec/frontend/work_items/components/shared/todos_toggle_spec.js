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
    handlers = [[createWorkItemTodosMutation, createTodoSuccessHandler]],
    currentUserTodos = [],
    todosButtonType = 'tertiary',
    glFeatures = {},
  } = {}) => {
    const mockApolloProvider = createMockApollo(handlers);

    wrapper = shallowMountExtended(TodosToggle, {
      apolloProvider: mockApolloProvider,
      provide: {
        glFeatures,
      },
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

  describe('when there is a pending to-do', () => {
    beforeEach(() => {
      createComponent({
        handlers: [
          [createWorkItemTodosMutation, createTodoSuccessHandler],
          [updateWorkItemCurrentUserTodosMutation, markAllDoneTodoSuccessHandler],
        ],
        currentUserTodos: [mockCurrentUserTodos],
      });
    });

    it('renders the mark to-do items done button', () => {
      expect(findAnimatedTodoIcon().attributes('name')).toEqual(TODO_DONE_ICON);
      expect(findAnimatedTodoIcon().props('isOn')).toBe(true);
      expect(findAnimatedTodoIcon().classes('!gl-text-status-info')).toBe(true);
    });

    it('calls the mark all done mutation on toggle', async () => {
      findTodoWidget().vm.$emit('click');

      await waitForPromises();

      expect(markAllDoneTodoSuccessHandler).toHaveBeenCalledWith({
        input: inputVariablesMarkAllDoneTodos,
        useWorkItemFeatures: false,
      });
      expect(wrapper.emitted('todosUpdated')[0][0]).toMatchObject({
        cache: expect.anything(),
        todos: [],
      });
      expect(updateGlobalTodoCount).toHaveBeenCalledWith(-1);
    });
  });

  describe('when workItemFeaturesField feature flag is enabled', () => {
    beforeEach(() => {
      createComponent({
        handlers: [
          [createWorkItemTodosMutation, createTodoSuccessHandler],
          [updateWorkItemCurrentUserTodosMutation, markAllDoneTodoSuccessHandler],
        ],
        currentUserTodos: [mockCurrentUserTodos],
        glFeatures: { workItemFeaturesField: true },
      });
    });

    it('passes useWorkItemFeatures as true to the mutation', async () => {
      findTodoWidget().vm.$emit('click');

      await waitForPromises();

      expect(markAllDoneTodoSuccessHandler).toHaveBeenCalledWith({
        input: inputVariablesMarkAllDoneTodos,
        useWorkItemFeatures: true,
      });
    });
  });

  describe('when there are no pending to-dos', () => {
    beforeEach(() => {
      createComponent({
        currentUserTodos: [],
      });
    });

    it('calls the create to-dos mutation on toggle', async () => {
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
  });

  describe('when there are multiple pending to-dos', () => {
    beforeEach(() => {
      createComponent({
        handlers: [
          [createWorkItemTodosMutation, createTodoSuccessHandler],
          [updateWorkItemCurrentUserTodosMutation, markAllDoneTodoSuccessHandler],
        ],
        currentUserTodos: mockMultipleCurrentUserTodos,
      });
    });

    it('decrements the global to-do count by the number of to-dos marked done on toggle', async () => {
      findTodoWidget().vm.$emit('click');

      await waitForPromises();

      expect(markAllDoneTodoSuccessHandler).toHaveBeenCalledWith({
        input: inputVariablesMarkAllDoneTodos,
        useWorkItemFeatures: false,
      });
      expect(updateGlobalTodoCount).toHaveBeenCalledWith(-3);
    });
  });

  describe('when todosButtonType is secondary', () => {
    beforeEach(() => {
      createComponent({
        todosButtonType: 'secondary',
      });
    });

    it('renders a secondary button', () => {
      expect(findTodoWidget().props('category')).toBe('secondary');
    });
  });

  describe('when the update mutation fails', () => {
    beforeEach(() => {
      createComponent({
        handlers: [[createWorkItemTodosMutation, failureHandler]],
      });
    });

    it('emits an error on toggle', async () => {
      findTodoWidget().vm.$emit('click');

      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([[errorMessage]]);
    });
  });
});
