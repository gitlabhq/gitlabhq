import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import SidebarTodoWidget from '~/sidebar/components/todo_toggle/sidebar_todo_widget.vue';
import epicTodoQuery from '~/sidebar/queries/epic_todo.query.graphql';
import TodoButton from '~/vue_shared/components/todo_button.vue';
import { todosResponse, noTodosResponse } from '../../mock_data';

jest.mock('~/flash');

Vue.use(VueApollo);

describe('Sidebar Todo Widget', () => {
  let wrapper;
  let fakeApollo;

  const findTodoButton = () => wrapper.findComponent(TodoButton);

  const createComponent = ({
    todosQueryHandler = jest.fn().mockResolvedValue(noTodosResponse),
  } = {}) => {
    fakeApollo = createMockApollo([[epicTodoQuery, todosQueryHandler]]);

    wrapper = shallowMount(SidebarTodoWidget, {
      apolloProvider: fakeApollo,
      provide: {
        canUpdate: true,
      },
      propsData: {
        fullPath: 'group',
        issuableIid: '1',
        issuableId: 'gid://gitlab/Epic/4',
        issuableType: 'epic',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    fakeApollo = null;
  });

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

  it('displays a flash message when query is rejected', async () => {
    createComponent({
      todosQueryHandler: jest.fn().mockRejectedValue('Houston, we have a problem'),
    });
    await waitForPromises();

    expect(createFlash).toHaveBeenCalled();
  });
});
