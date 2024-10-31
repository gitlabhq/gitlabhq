import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import todoMarkDoneMutation from '~/graphql_shared/mutations/todo_mark_done.mutation.graphql';
import SidebarTodo from '~/vue_shared/alert_details/components/sidebar/sidebar_todo.vue';
import createAlertTodoMutation from '~/vue_shared/alert_details/graphql/mutations/alert_todo_create.mutation.graphql';
import alertQuery from '~/vue_shared/alert_details/graphql/queries/alert_sidebar_details.query.graphql';
import waitForPromises from 'jest/__helpers__/wait_for_promises';
import mockAlerts from './mocks/alerts.json';

const mockAlert = mockAlerts[1];

describe('Alert Details Sidebar To Do', () => {
  let wrapper;
  let requestHandler;

  const defaultHandler = {
    createAlertTodo: jest
      .fn()
      .mockResolvedValue({ data: { alertTodoCreate: { errors: [], alert: mockAlert } } }),
    markAsDone: jest
      .fn()
      .mockResolvedValue({ data: { todoMarkDone: { errors: [], todo: { id: 1234 } } } }),
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
    const propsData = {
      alert: { ...mockAlert },
      ...data,
      sidebarCollapsed,
      projectPath: 'projectPath',
    };
    const fakeApollo = createMockApolloProvider(handler);

    fakeApollo.clients.defaultClient.cache.writeQuery({
      query: alertQuery,
      variables: {
        fullPath: propsData.projectPath,
        alertId: propsData.alert.iid,
      },
      data: {
        project: {
          id: '1',
          alertManagementAlerts: {
            nodes: [propsData.alert],
          },
        },
      },
    });

    wrapper = mount(SidebarTodo, {
      apolloProvider: fakeApollo,
      propsData,
    });
  }

  const findToDoButton = () => wrapper.find('[data-testid="alert-todo-button"]');

  describe('updating the alert to do', () => {
    describe('adding a todo', () => {
      beforeEach(() => {
        mountComponent({
          sidebarCollapsed: false,
        });
      });

      it('renders a button for adding a To-Do', async () => {
        await nextTick();

        expect(findToDoButton().text()).toBe('Add a to-do item');
      });

      it('calls `$apollo.mutate` with `createAlertTodoMutation` mutation and variables containing `iid`, `todoEvent`, & `projectPath`', async () => {
        findToDoButton().trigger('click');
        await nextTick();

        expect(requestHandler.createAlertTodo).toHaveBeenCalledWith(
          expect.objectContaining({
            iid: '1527543',
            projectPath: 'projectPath',
          }),
        );
      });

      it('triggers an update of the todo count', async () => {
        const dispatchEventSpy = jest.spyOn(document, 'dispatchEvent');

        findToDoButton().trigger('click');
        await waitForPromises();

        expect(dispatchEventSpy).toHaveBeenCalledTimes(1);
        const dispatchedEvent = dispatchEventSpy.mock.calls[0][0];
        expect(dispatchedEvent.detail).toEqual({ delta: 1 });
        expect(dispatchedEvent.type).toBe('todo:toggle');
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

      it('triggers an update of the todo count', async () => {
        const dispatchEventSpy = jest.spyOn(document, 'dispatchEvent');

        findToDoButton().trigger('click');
        await waitForPromises();

        expect(dispatchEventSpy).toHaveBeenCalledTimes(1);
        const dispatchedEvent = dispatchEventSpy.mock.calls[0][0];
        expect(dispatchedEvent.detail).toEqual({ delta: -1 });
        expect(dispatchedEvent.type).toBe('todo:toggle');
      });
    });
  });
});
