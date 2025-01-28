import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import deleteWorkItemMutation from '~/work_items/graphql/delete_work_item.mutation.graphql';
import workspacePermissionsQuery from '~/work_items/graphql/workspace_permissions.query.graphql';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';
import {
  deleteWorkItemMutationErrorResponse,
  deleteWorkItemResponse,
  mockProjectPermissionsQueryResponse,
} from '../mock_data';

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

  const WorkItemDetailStub = {
    template: '<div data-testid="work-item-stub"> Work Item </div>',
    props: ['workItemId', 'workItemIid'],
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findWorkItemDetail = () => wrapper.findComponent(WorkItemDetail);

  const workspacePermissionsHandler = jest
    .fn()
    .mockResolvedValue(mockProjectPermissionsQueryResponse());

  const createComponent = ({
    deleteWorkItemMutationHandler = jest.fn().mockResolvedValue(deleteWorkItemResponse),
    stubs = {},
  } = {}) => {
    const apolloProvider = createMockApollo([
      [deleteWorkItemMutation, deleteWorkItemMutationHandler],
      [workspacePermissionsQuery, workspacePermissionsHandler],
    ]);

    wrapper = shallowMount(WorkItemDetailModal, {
      apolloProvider,
      propsData: {
        workItemId,
        workItemIid: '1',
      },
      provide: {
        fullPath: 'group/project',
        reportAbusePath: 'report/abuse',
        groupPath: '',
        hasSubepicsFeature: false,
        hasLinkedItemsEpicsFeature: true,
      },
      stubs: {
        GlModal,
        WorkItemDetail,
        ...stubs,
      },
    });
  };

  it('renders WorkItemDetail', () => {
    createComponent();

    expect(findWorkItemDetail().props()).toEqual({
      isModal: true,
      workItemId,
      workItemIid: '1',
      modalWorkItemFullPath: '',
      newCommentTemplatePaths: [],
      isDrawer: false,
      modalIsGroup: null,
    });
  });

  it('renders alert if there is an error', async () => {
    createComponent({
      deleteWorkItemMutationHandler: jest.fn().mockRejectedValue({ message: 'message' }),
    });

    findWorkItemDetail().vm.$emit('deleteWorkItem');
    await waitForPromises();

    expect(findAlert().exists()).toBe(true);
  });

  it('does not render alert if there is no error', () => {
    createComponent();

    expect(findAlert().exists()).toBe(false);
  });

  it('dismisses the alert on `dismiss` emitted event', async () => {
    createComponent({
      deleteWorkItemMutationHandler: jest.fn().mockRejectedValue({ message: 'message' }),
    });

    findWorkItemDetail().vm.$emit('deleteWorkItem');
    await waitForPromises();

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

    findWorkItemDetail().vm.$emit('close');

    expect(hideModal).toHaveBeenCalled();
  });

  it('updates the work item when WorkItemDetail emits `update-modal` event', async () => {
    createComponent({
      stubs: {
        WorkItemDetail: WorkItemDetailStub,
      },
    });

    const workItemDetailComponent = wrapper.find('[data-testid="work-item-stub"]');
    workItemDetailComponent.vm.$emit('update-modal', undefined, {
      iid: '2',
      id: 'gid://gitlab/WorkItem/2',
    });
    await nextTick();

    expect(workItemDetailComponent.props('workItemIid')).toBe('2');
    expect(workItemDetailComponent.props('workItemId')).toBe('gid://gitlab/WorkItem/2');
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
