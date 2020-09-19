import { mount } from '@vue/test-utils';
import SidebarTodo from '~/alert_management/components/sidebar/sidebar_todo.vue';
import createAlertTodoMutation from '~/alert_management/graphql/mutations/alert_todo_create.mutation.graphql';
import todoMarkDoneMutation from '~/graphql_shared/mutations/todo_mark_done.mutation.graphql';
import mockAlerts from '../mocks/alerts.json';

const mockAlert = mockAlerts[0];

describe('Alert Details Sidebar To Do', () => {
  let wrapper;

  function mountComponent({ data, sidebarCollapsed = true, loading = false, stubs = {} } = {}) {
    wrapper = mount(SidebarTodo, {
      propsData: {
        alert: { ...mockAlert },
        ...data,
        sidebarCollapsed,
        projectPath: 'projectPath',
      },
      mocks: {
        $apollo: {
          mutate: jest.fn(),
          queries: {
            alert: {
              loading,
            },
          },
        },
      },
      stubs,
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  const findToDoButton = () => wrapper.find('[data-testid="alert-todo-button"]');

  describe('updating the alert to do', () => {
    const mockUpdatedMutationResult = {
      data: {
        updateAlertTodo: {
          errors: [],
          alert: {},
        },
      },
    };

    describe('adding a todo', () => {
      beforeEach(() => {
        mountComponent({
          data: { alert: mockAlert },
          sidebarCollapsed: false,
          loading: false,
        });
      });

      it('renders a button for adding a To-Do', async () => {
        await wrapper.vm.$nextTick();

        expect(findToDoButton().text()).toBe('Add a To-Do');
      });

      it('calls `$apollo.mutate` with `createAlertTodoMutation` mutation and variables containing `iid`, `todoEvent`, & `projectPath`', async () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockUpdatedMutationResult);

        findToDoButton().trigger('click');
        await wrapper.vm.$nextTick();

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
          mutation: createAlertTodoMutation,
          variables: {
            iid: '1527542',
            projectPath: 'projectPath',
          },
        });
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
        await wrapper.vm.$nextTick();

        expect(findToDoButton().text()).toBe('Mark as done');
      });

      it('calls `$apollo.mutate` with `todoMarkDoneMutation` mutation and variables containing `id`', async () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockUpdatedMutationResult);

        findToDoButton().trigger('click');
        await wrapper.vm.$nextTick();

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
          mutation: todoMarkDoneMutation,
          update: expect.anything(),
          variables: {
            id: '1234',
          },
        });
      });
    });
  });
});
