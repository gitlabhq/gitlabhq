import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import deleteWorkItemMutation from '~/work_items/graphql/delete_work_item.mutation.graphql';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';
import { deleteWorkItemMutationErrorResponse, deleteWorkItemResponse } from '../mock_data';

describe('WorkItemDetailModal component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const workItemId = 'gid://gitlab/WorkItem/1';
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

  const findModal = () => wrapper.findComponent(GlModal);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findWorkItemDetail = () => wrapper.findComponent(WorkItemDetail);

  const createComponent = ({
    error = false,
    deleteWorkItemMutationHandler = jest.fn().mockResolvedValue(deleteWorkItemResponse),
  } = {}) => {
    const apolloProvider = createMockApollo([
      [deleteWorkItemMutation, deleteWorkItemMutationHandler],
    ]);

    wrapper = shallowMount(WorkItemDetailModal, {
      apolloProvider,
      propsData: {
        workItemId,
        workItemIid: '1',
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
      workItemId,
      workItemIid: '1',
      workItemParentId: null,
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
    it('emits workItemDeleted and closes modal', async () => {
      const mutationMock = jest.fn().mockResolvedValue(deleteWorkItemResponse);
      createComponent({ deleteWorkItemMutationHandler: mutationMock });

      findWorkItemDetail().vm.$emit('deleteWorkItem');
      await waitForPromises();

      expect(wrapper.emitted('workItemDeleted')).toEqual([[workItemId]]);
      expect(hideModal).toHaveBeenCalled();
      expect(mutationMock).toHaveBeenCalledWith({ input: { id: workItemId } });
    });

    it.each`
      errorType                              | mutationMock                                                        | errorMessage
      ${'an error in the mutation response'} | ${jest.fn().mockResolvedValue(deleteWorkItemMutationErrorResponse)} | ${'Error'}
      ${'a network error'}                   | ${jest.fn().mockRejectedValue(new Error('GraphQL networkError'))}   | ${'GraphQL networkError'}
    `('shows an error message when there is $errorType', async ({ mutationMock, errorMessage }) => {
      createComponent({ deleteWorkItemMutationHandler: mutationMock });

      findWorkItemDetail().vm.$emit('deleteWorkItem');
      await waitForPromises();

      expect(wrapper.emitted('workItemDeleted')).toBeUndefined();
      expect(hideModal).not.toHaveBeenCalled();
      expect(findAlert().text()).toBe(errorMessage);
    });
  });
});
