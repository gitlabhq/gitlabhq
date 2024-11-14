import { GlButton, GlAnimatedTodoIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { createMockSubscription } from 'mock-apollo-client';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import SidebarTodoWidget from '~/sidebar/components/todo_toggle/sidebar_todo_widget.vue';
import epicTodoQuery from '~/sidebar/queries/epic_todo.query.graphql';
import mergeRequestTodoQuery from '~/sidebar/queries/merge_request_todo.query.graphql';
import mergeRequestTodoSubscription from '~/sidebar/queries/merge_request_todo.subscription.graphql';
import TodoButton from '~/sidebar/components/todo_toggle/todo_button.vue';
import { todosResponse, noMergeRequestTodosResponse, noTodosResponse } from '../../mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('Sidebar Todo Widget', () => {
  let wrapper;

  const findTodoButton = () => wrapper.findComponent(TodoButton);

  const createComponent = ({
    todosQueryHandler = jest.fn().mockResolvedValue(noTodosResponse),
    provide = {},
    propsData = {},
    apolloProvider = createMockApollo([[epicTodoQuery, todosQueryHandler]]),
  } = {}) => {
    wrapper = shallowMount(SidebarTodoWidget, {
      apolloProvider,
      provide: {
        canUpdate: true,
        isClassicSidebar: true,
        ...provide,
      },
      propsData: {
        fullPath: 'group',
        issuableIid: '1',
        issuableId: 'gid://gitlab/Epic/4',
        issuableType: 'epic',
        ...propsData,
      },
    });
  };

  describe('when user does not have a todo for the issuable', () => {
    beforeEach(() => {
      createComponent();
      return waitForPromises();
    });

    it('passes false isTodo prop to Todo button component', () => {
      expect(findTodoButton().props('isTodo')).toBe(false);
    });

    it('emits `todoUpdated` event with a `false` payload', () => {
      expect(wrapper.emitted('todoUpdated')).toEqual([[false]]);
    });
  });

  describe('when user has a todo for the issuable', () => {
    beforeEach(() => {
      createComponent({
        todosQueryHandler: jest.fn().mockResolvedValue(todosResponse),
      });
      return waitForPromises();
    });

    it('passes true isTodo prop to Todo button component', () => {
      expect(findTodoButton().props('isTodo')).toBe(true);
    });

    it('emits `todoUpdated` event with a `true` payload', () => {
      expect(wrapper.emitted('todoUpdated')).toEqual([[true]]);
    });
  });

  it('displays an alert message when query is rejected', async () => {
    createComponent({
      todosQueryHandler: jest.fn().mockRejectedValue('Houston, we have a problem'),
    });
    await waitForPromises();

    expect(createAlert).toHaveBeenCalled();
  });

  describe('collapsed', () => {
    const event = { stopPropagation: jest.fn(), preventDefault: jest.fn() };

    beforeEach(() => {
      createComponent({
        todosQueryHandler: jest.fn().mockResolvedValue(noTodosResponse),
      });
      return waitForPromises();
    });

    it('shows add todo icon', () => {
      expect(wrapper.findComponent(GlAnimatedTodoIcon).exists()).toBe(true);

      expect(wrapper.findComponent(GlAnimatedTodoIcon).props('isOn')).toBe(false);
    });

    it('sets default tooltip title', () => {
      expect(wrapper.findComponent(GlButton).attributes('title')).toBe('Add a to-do item');
    });

    it('when user has a to-do item', async () => {
      createComponent({
        todosQueryHandler: jest.fn().mockResolvedValue(todosResponse),
      });

      await waitForPromises();
      expect(wrapper.findComponent(GlAnimatedTodoIcon).props('isOn')).toBe(true);
      expect(wrapper.findComponent(GlButton).attributes('title')).toBe('Mark as done');
    });

    it('emits `todoUpdated` event on click on icon', async () => {
      wrapper.findComponent(GlAnimatedTodoIcon).vm.$emit('click', event);

      await nextTick();
      expect(wrapper.emitted('todoUpdated')).toEqual([[false]]);
    });
  });

  describe('when the query is pending', () => {
    it('is in the loading state', () => {
      createComponent();

      expect(findTodoButton().attributes('loading')).toBe('true');
    });

    it('is not in the loading state if notificationsTodosButtons feature flag is enabled', () => {
      createComponent({
        provide: {
          glFeatures: { notificationsTodosButtons: true },
        },
      });

      expect(findTodoButton().attributes('loading')).toBeUndefined();
      expect(findTodoButton().attributes().disabled).toBe('true');
    });
  });

  describe('for merge request issuable type', () => {
    let mockSubscription;
    let subscriptionHandler;
    let apolloProvider;

    beforeEach(() => {
      mockSubscription = createMockSubscription();
      subscriptionHandler = jest.fn().mockReturnValue(mockSubscription);
      apolloProvider = createMockApollo([
        [mergeRequestTodoQuery, jest.fn().mockResolvedValue(noMergeRequestTodosResponse)],
      ]);

      apolloProvider.defaultClient.setRequestHandler(
        mergeRequestTodoSubscription,
        subscriptionHandler,
      );

      createComponent({
        propsData: { issuableType: 'merge_request' },
        apolloProvider,
      });

      return nextTick();
    });

    it('updates todo button to have a new todo when subscription receives data', async () => {
      mockSubscription.next({
        data: {
          issuableTodoUpdated: {
            __typename: 'MergeRequest',
            id: 'gid://gitlab/MergeRequest/1',
            currentUserTodos: {
              nodes: [{ id: 1 }],
            },
          },
        },
      });

      await nextTick();

      expect(subscriptionHandler).toHaveBeenCalled();
      expect(findTodoButton().props('isTodo')).toBe(true);
    });
  });
});
