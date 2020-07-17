import { mount } from '@vue/test-utils';
import SidebarTodo from '~/alert_management/components/sidebar/sidebar_todo.vue';
import AlertMarkTodo from '~/alert_management/graphql/mutations/alert_todo_create.graphql';
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

  describe('updating the alert to do', () => {
    const mockUpdatedMutationResult = {
      data: {
        updateAlertTodo: {
          errors: [],
          alert: {},
        },
      },
    };

    beforeEach(() => {
      mountComponent({
        data: { alert: mockAlert },
        sidebarCollapsed: false,
        loading: false,
      });
    });

    it('renders a button for adding a To Do', () => {
      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find('[data-testid="alert-todo-button"]').text()).toBe('Add a To Do');
      });
    });

    it('calls `$apollo.mutate` with `AlertMarkTodo` mutation and variables containing `iid`, `todoEvent`, & `projectPath`', () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockUpdatedMutationResult);

      return wrapper.vm.$nextTick().then(() => {
        wrapper.find('button').trigger('click');
        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
          mutation: AlertMarkTodo,
          variables: {
            iid: '1527542',
            projectPath: 'projectPath',
          },
        });
      });
    });
  });
});
