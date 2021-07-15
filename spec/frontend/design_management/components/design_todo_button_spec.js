import { shallowMount, mount } from '@vue/test-utils';
import DesignTodoButton from '~/design_management/components/design_todo_button.vue';
import createDesignTodoMutation from '~/design_management/graphql/mutations/create_design_todo.mutation.graphql';
import todoMarkDoneMutation from '~/graphql_shared/mutations/todo_mark_done.mutation.graphql';
import TodoButton from '~/vue_shared/components/sidebar/todo_toggle/todo_button.vue';
import mockDesign from '../mock_data/design';

const mockDesignWithPendingTodos = {
  ...mockDesign,
  currentUserTodos: {
    nodes: [
      {
        id: 'todo-id',
      },
    ],
  },
};

const mutate = jest.fn().mockResolvedValue();

describe('Design management design todo button', () => {
  let wrapper;

  function createComponent(props = {}, { mountFn = shallowMount } = {}) {
    wrapper = mountFn(DesignTodoButton, {
      propsData: {
        design: mockDesign,
        ...props,
      },
      provide: {
        projectPath: 'project-path',
        issueIid: '10',
      },
      mocks: {
        $route: {
          params: {
            id: 'my-design.jpg',
          },
          query: {},
        },
        $apollo: {
          mutate,
        },
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    jest.clearAllMocks();
  });

  it('renders TodoButton component', () => {
    expect(wrapper.find(TodoButton).exists()).toBe(true);
  });

  describe('when design has a pending todo', () => {
    beforeEach(() => {
      createComponent({ design: mockDesignWithPendingTodos }, { mountFn: mount });
    });

    it('renders correct button text', () => {
      expect(wrapper.text()).toBe('Mark as done');
    });

    describe('when clicked', () => {
      let dispatchEventSpy;

      beforeEach(() => {
        dispatchEventSpy = jest.spyOn(document, 'dispatchEvent');
        jest.spyOn(document, 'querySelector').mockReturnValue({
          innerText: 2,
        });

        createComponent({ design: mockDesignWithPendingTodos }, { mountFn: mount });
        wrapper.trigger('click');
        return wrapper.vm.$nextTick();
      });

      it('calls `$apollo.mutate` with the `todoMarkDone` mutation and variables containing `id`', async () => {
        const todoMarkDoneMutationVariables = {
          mutation: todoMarkDoneMutation,
          update: expect.anything(),
          variables: {
            id: 'todo-id',
          },
        };

        expect(mutate).toHaveBeenCalledTimes(1);
        expect(mutate).toHaveBeenCalledWith(todoMarkDoneMutationVariables);
      });

      it('calls dispatchDocumentEvent to update global To-Do counter correctly', () => {
        const dispatchedEvent = dispatchEventSpy.mock.calls[0][0];

        expect(dispatchEventSpy).toHaveBeenCalledTimes(1);
        expect(dispatchedEvent.detail).toEqual({ count: 1 });
        expect(dispatchedEvent.type).toBe('todo:toggle');
      });
    });
  });

  describe('when design has no pending todos', () => {
    beforeEach(() => {
      createComponent({}, { mountFn: mount });
    });

    it('renders correct button text', () => {
      expect(wrapper.text()).toBe('Add a to do');
    });

    describe('when clicked', () => {
      let dispatchEventSpy;

      beforeEach(() => {
        dispatchEventSpy = jest.spyOn(document, 'dispatchEvent');
        jest.spyOn(document, 'querySelector').mockReturnValue({
          innerText: 2,
        });

        createComponent({}, { mountFn: mount });
        wrapper.trigger('click');
        return wrapper.vm.$nextTick();
      });

      it('calls `$apollo.mutate` with the `createDesignTodoMutation` mutation and variables containing `issuable_id`, `issue_id`, & `projectPath`', async () => {
        const createDesignTodoMutationVariables = {
          mutation: createDesignTodoMutation,
          update: expect.anything(),
          variables: {
            atVersion: null,
            filenames: ['my-design.jpg'],
            designId: '1',
            issueId: '1',
            issueIid: '10',
            projectPath: 'project-path',
          },
        };

        expect(mutate).toHaveBeenCalledTimes(1);
        expect(mutate).toHaveBeenCalledWith(createDesignTodoMutationVariables);
      });

      it('calls dispatchDocumentEvent to update global To-Do counter correctly', () => {
        const dispatchedEvent = dispatchEventSpy.mock.calls[0][0];

        expect(dispatchEventSpy).toHaveBeenCalledTimes(1);
        expect(dispatchedEvent.detail).toEqual({ count: 3 });
        expect(dispatchedEvent.type).toBe('todo:toggle');
      });
    });
  });
});
