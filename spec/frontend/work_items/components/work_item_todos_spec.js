import { GlButton, GlIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemTodos from '~/work_items/components/work_item_todos.vue';
import { ADD, TODO_DONE_ICON, TODO_ADD_ICON } from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import { updateGlobalTodoCount } from '~/sidebar/utils';
import { workItemResponseFactory, updateWorkItemMutationResponseFactory } from '../mock_data';

jest.mock('~/sidebar/utils');

describe('WorkItemTodo component', () => {
  Vue.use(VueApollo);

  let wrapper;

  const findTodoWidget = () => wrapper.findComponent(GlButton);
  const findTodoIcon = () => wrapper.findComponent(GlIcon);

  const errorMessage = 'Failed to add item';
  const workItemQueryResponse = workItemResponseFactory({ canUpdate: true });
  const successHandler = jest
    .fn()
    .mockResolvedValue(updateWorkItemMutationResponseFactory({ canUpdate: true }));
  const failureHandler = jest.fn().mockRejectedValue(new Error(errorMessage));

  const inputVariables = {
    id: 'gid://gitlab/WorkItem/1',
    currentUserTodosWidget: {
      action: ADD,
    },
  };

  const createComponent = ({
    currentUserTodosMock = [updateWorkItemMutation, successHandler],
    currentUserTodos = [],
  } = {}) => {
    const handlers = [currentUserTodosMock];
    wrapper = shallowMountExtended(WorkItemTodos, {
      apolloProvider: createMockApollo(handlers),
      propsData: {
        workItem: workItemQueryResponse.data.workItem,
        currentUserTodos,
      },
    });
  };

  it('renders the widget', () => {
    createComponent();

    expect(findTodoWidget().exists()).toBe(true);
    expect(findTodoIcon().props('name')).toEqual(TODO_ADD_ICON);
    expect(findTodoIcon().classes('gl-fill-blue-500')).toBe(false);
  });

  it('renders mark as done button when there is pending item', () => {
    createComponent({
      currentUserTodos: [
        {
          node: {
            id: 'gid://gitlab/Todo/1',
            state: 'pending',
          },
        },
      ],
    });

    expect(findTodoIcon().props('name')).toEqual(TODO_DONE_ICON);
    expect(findTodoIcon().classes('gl-fill-blue-500')).toBe(true);
  });

  it('calls update mutation when to do button is clicked', async () => {
    createComponent();

    findTodoWidget().vm.$emit('click');

    await waitForPromises();

    expect(successHandler).toHaveBeenCalledWith({
      input: inputVariables,
    });
    expect(updateGlobalTodoCount).toHaveBeenCalled();
  });

  it('emits error when the update mutation fails', async () => {
    createComponent({ currentUserTodosMock: [updateWorkItemMutation, failureHandler] });

    findTodoWidget().vm.$emit('click');

    await waitForPromises();

    expect(wrapper.emitted('error')).toEqual([[errorMessage]]);
  });
});
