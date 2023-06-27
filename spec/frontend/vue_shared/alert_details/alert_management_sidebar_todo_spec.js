import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import todoMarkDoneMutation from '~/graphql_shared/mutations/todo_mark_done.mutation.graphql';
import SidebarTodo from '~/vue_shared/alert_details/components/sidebar/sidebar_todo.vue';
import createAlertTodoMutation from '~/vue_shared/alert_details/graphql/mutations/alert_todo_create.mutation.graphql';
import mockAlerts from './mocks/alerts.json';

const mockAlert = mockAlerts[0];

describe('Alert Details Sidebar To Do', () => {
  let wrapper;
  let requestHandler;

  const defaultHandler = {
    createAlertTodo: jest.fn().mockResolvedValue({}),
    markAsDone: jest.fn().mockResolvedValue({}),
  };

  const createMockApolloProvider = (handler) => {
    Vue.use(VueApollo);

    requestHandler = handler;

    return createMockApollo([
      [todoMarkDoneMutation, handler.markAsDone],
      [createAlertTodoMutation, handler.createAlertTodo],
    ]);
  };

  function mountComponent({ data, sidebarCollapsed = true, handler = defaultHandler } = {}) {
    wrapper = mount(SidebarTodo, {
      apolloProvider: createMockApolloProvider(handler),
      propsData: {
        alert: { ...mockAlert },
        ...data,
        sidebarCollapsed,
        projectPath: 'projectPath',
      },
    });
  }

  const findToDoButton = () => wrapper.find('[data-testid="alert-todo-button"]');

  describe('updating the alert to do', () => {
    describe('adding a todo', () => {
      beforeEach(() => {
        mountComponent({
          data: { alert: mockAlert },
          sidebarCollapsed: false,
          loading: false,
        });
      });

      it('renders a button for adding a To-Do', async () => {
        await nextTick();

        expect(findToDoButton().text()).toBe('Add a to do');
      });

      it('calls `$apollo.mutate` with `createAlertTodoMutation` mutation and variables containing `iid`, `todoEvent`, & `projectPath`', async () => {
        findToDoButton().trigger('click');
        await nextTick();

        expect(requestHandler.createAlertTodo).toHaveBeenCalledWith(
          expect.objectContaining({
            iid: '1527542',
            projectPath: 'projectPath',
          }),
        );
      });
    });

    describe('removing a todo', () => {
      beforeEach(() => {
        mountComponent({
          data: { alert: { ...mockAlert, todos: { nodes: [{ id: '1234' }] } } },
          sidebarCollapsed: false,
          loading: false,
        });
      });

      it('renders a Mark As Done button when todo is present', async () => {
        await nextTick();

        expect(findToDoButton().text()).toBe('Mark as done');
      });

      it('calls `$apollo.mutate` with `todoMarkDoneMutation` mutation and variables containing `id`', async () => {
        findToDoButton().trigger('click');
        await nextTick();

        expect(requestHandler.markAsDone).toHaveBeenCalledWith({
          id: '1234',
        });
      });
    });
  });
});
