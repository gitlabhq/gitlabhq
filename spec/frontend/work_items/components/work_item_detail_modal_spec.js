import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import deleteWorkItemFromTaskMutation from '~/work_items/graphql/delete_task_from_work_item.mutation.graphql';
import deleteWorkItemMutation from '~/work_items/graphql/delete_work_item.mutation.graphql';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';
import {
  deleteWorkItemFromTaskMutationErrorResponse,
  deleteWorkItemFromTaskMutationResponse,
  deleteWorkItemMutationErrorResponse,
  deleteWorkItemResponse,
} from '../mock_data';

describe('WorkItemDetailModal component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const hideModal = jest.fn();
  const GlModal = {
    template: `
    <div>
      <slot></slot>
    </div>
  `,
    methods: {
      hide: hideModal,
    },
  };

  const defaultPropsData = {
    issueGid: 'gid://gitlab/WorkItem/1',
    workItemId: 'gid://gitlab/WorkItem/2',
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findWorkItemDetail = () => wrapper.findComponent(WorkItemDetail);

  const createComponent = ({
    lockVersion,
    lineNumberStart,
    lineNumberEnd,
    error = false,
    deleteWorkItemFromTaskMutationHandler = jest
      .fn()
      .mockResolvedValue(deleteWorkItemFromTaskMutationResponse),
    deleteWorkItemMutationHandler = jest.fn().mockResolvedValue(deleteWorkItemResponse),
  } = {}) => {
    const apolloProvider = createMockApollo([
      [deleteWorkItemFromTaskMutation, deleteWorkItemFromTaskMutationHandler],
      [deleteWorkItemMutation, deleteWorkItemMutationHandler],
    ]);

    wrapper = shallowMount(WorkItemDetailModal, {
      apolloProvider,
      propsData: {
        ...defaultPropsData,
        lockVersion,
        lineNumberStart,
        lineNumberEnd,
      },
      data() {
        return {
          error,
        };
      },
      provide: {
        fullPath: 'group/project',
      },
      stubs: {
        GlModal,
        WorkItemDetail: stubComponent(WorkItemDetail, {
          apollo: {},
        }),
      },
    });
  };

  it('renders WorkItemDetail', () => {
    createComponent();

    expect(findWorkItemDetail().props()).toEqual({
      isModal: true,
      workItemId: defaultPropsData.workItemId,
      workItemParentId: defaultPropsData.issueGid,
      workItemIid: null,
    });
  });

  it('renders alert if there is an error', () => {
    createComponent({ error: true });

    expect(findAlert().exists()).toBe(true);
  });

  it('does not render alert if there is no error', () => {
    createComponent();

    expect(findAlert().exists()).toBe(false);
  });

  it('dismisses the alert on `dismiss` emitted event', async () => {
    createComponent({ error: true });
    findAlert().vm.$emit('dismiss');
    await nextTick();

    expect(findAlert().exists()).toBe(false);
  });

  it('emits `close` event on hiding the modal', () => {
    createComponent();
    findModal().vm.$emit('hide');

    expect(wrapper.emitted('close')).toHaveLength(1);
  });

  it('hides the modal when WorkItemDetail emits `close` event', () => {
    createComponent();
    const closeSpy = jest.spyOn(wrapper.vm.$refs.modal, 'hide');

    findWorkItemDetail().vm.$emit('close');

    expect(closeSpy).toHaveBeenCalled();
  });

  it('updates the work item when WorkItemDetail emits `update-modal` event', async () => {
    createComponent();

    findWorkItemDetail().vm.$emit('update-modal', undefined, {
      id: 'updatedId',
      iid: 'updatedIid',
    });
    await waitForPromises();

    expect(findWorkItemDetail().props().workItemId).toEqual('updatedId');
    expect(findWorkItemDetail().props().workItemIid).toEqual('updatedIid');
  });

  describe('delete work item', () => {
    describe('when there is task data', () => {
      it('emits workItemDeleted and closes modal', async () => {
        const mutationMock = jest.fn().mockResolvedValue(deleteWorkItemFromTaskMutationResponse);
        createComponent({
          lockVersion: 1,
          lineNumberStart: '3',
          lineNumberEnd: '3',
          deleteWorkItemFromTaskMutationHandler: mutationMock,
        });
        const newDesc = 'updated work item desc';

        findWorkItemDetail().vm.$emit('deleteWorkItem');
        await waitForPromises();

        expect(wrapper.emitted('workItemDeleted')).toEqual([[newDesc]]);
        expect(hideModal).toHaveBeenCalled();
        expect(mutationMock).toHaveBeenCalledWith({
          input: {
            id: defaultPropsData.issueGid,
            lockVersion: 1,
            taskData: { id: defaultPropsData.workItemId, lineNumberEnd: 3, lineNumberStart: 3 },
          },
        });
      });

      it.each`
        errorType                              | mutationMock                                                                | errorMessage
        ${'an error in the mutation response'} | ${jest.fn().mockResolvedValue(deleteWorkItemFromTaskMutationErrorResponse)} | ${'Error'}
        ${'a network error'}                   | ${jest.fn().mockRejectedValue(new Error('GraphQL networkError'))}           | ${'GraphQL networkError'}
      `(
        'shows an error message when there is $errorType',
        async ({ mutationMock, errorMessage }) => {
          createComponent({
            lockVersion: 1,
            lineNumberStart: '3',
            lineNumberEnd: '3',
            deleteWorkItemFromTaskMutationHandler: mutationMock,
          });

          findWorkItemDetail().vm.$emit('deleteWorkItem');
          await waitForPromises();

          expect(wrapper.emitted('workItemDeleted')).toBeUndefined();
          expect(hideModal).not.toHaveBeenCalled();
          expect(findAlert().text()).toBe(errorMessage);
        },
      );
    });

    describe('when there is no task data', () => {
      it('emits workItemDeleted and closes modal', async () => {
        const mutationMock = jest.fn().mockResolvedValue(deleteWorkItemResponse);
        createComponent({ deleteWorkItemMutationHandler: mutationMock });

        findWorkItemDetail().vm.$emit('deleteWorkItem');
        await waitForPromises();

        expect(wrapper.emitted('workItemDeleted')).toEqual([[defaultPropsData.workItemId]]);
        expect(hideModal).toHaveBeenCalled();
        expect(mutationMock).toHaveBeenCalledWith({ input: { id: defaultPropsData.workItemId } });
      });

      it.each`
        errorType                              | mutationMock                                                        | errorMessage
        ${'an error in the mutation response'} | ${jest.fn().mockResolvedValue(deleteWorkItemMutationErrorResponse)} | ${'Error'}
        ${'a network error'}                   | ${jest.fn().mockRejectedValue(new Error('GraphQL networkError'))}   | ${'GraphQL networkError'}
      `(
        'shows an error message when there is $errorType',
        async ({ mutationMock, errorMessage }) => {
          createComponent({ deleteWorkItemMutationHandler: mutationMock });

          findWorkItemDetail().vm.$emit('deleteWorkItem');
          await waitForPromises();

          expect(wrapper.emitted('workItemDeleted')).toBeUndefined();
          expect(hideModal).not.toHaveBeenCalled();
          expect(findAlert().text()).toBe(errorMessage);
        },
      );
    });
  });
});
