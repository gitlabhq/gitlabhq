import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import deleteWorkItemFromTaskMutation from '~/work_items/graphql/delete_task_from_work_item.mutation.graphql';

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

  const findModal = () => wrapper.findComponent(GlModal);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findWorkItemDetail = () => wrapper.findComponent(WorkItemDetail);

  const createComponent = ({ workItemId = '1', issueGid = '2', error = false } = {}) => {
    const apolloProvider = createMockApollo([
      [
        deleteWorkItemFromTaskMutation,
        jest.fn().mockResolvedValue({
          data: {
            workItemDeleteTask: {
              workItem: { id: 123, descriptionHtml: 'updated work item desc' },
              errors: [],
            },
          },
        }),
      ],
    ]);

    wrapper = shallowMount(WorkItemDetailModal, {
      apolloProvider,
      propsData: { workItemId, issueGid },
      data() {
        return {
          error,
        };
      },
      stubs: {
        GlModal,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders WorkItemDetail', () => {
    createComponent();

    expect(findWorkItemDetail().props()).toEqual({
      isModal: true,
      workItemId: '1',
      workItemParentId: '2',
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

    expect(wrapper.emitted('close')).toBeTruthy();
  });

  it('hides the modal when WorkItemDetail emits `close` event', () => {
    createComponent();
    const closeSpy = jest.spyOn(wrapper.vm.$refs.modal, 'hide');

    findWorkItemDetail().vm.$emit('close');

    expect(closeSpy).toHaveBeenCalled();
  });

  describe('delete work item', () => {
    it('emits workItemDeleted and closes modal', async () => {
      createComponent();
      const newDesc = 'updated work item desc';

      findWorkItemDetail().vm.$emit('deleteWorkItem');

      await waitForPromises();

      expect(wrapper.emitted('workItemDeleted')).toEqual([[newDesc]]);
      expect(hideModal).toHaveBeenCalled();
    });
  });
});
