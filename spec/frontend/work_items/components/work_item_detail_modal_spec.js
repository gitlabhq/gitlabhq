import { GlModal, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';

describe('WorkItemDetailModal component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const findModal = () => wrapper.findComponent(GlModal);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findWorkItemDetail = () => wrapper.findComponent(WorkItemDetail);

  const createComponent = ({ workItemId = '1', error = false } = {}) => {
    wrapper = shallowMount(WorkItemDetailModal, {
      propsData: { workItemId },
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

    expect(findWorkItemDetail().props()).toEqual({ workItemId: '1' });
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

  it('emits `workItemDeleted` event on deleting work item', () => {
    createComponent();
    findWorkItemDetail().vm.$emit('workItemDeleted');

    expect(wrapper.emitted('workItemDeleted')).toBeTruthy();
  });
});
