import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import WorkItemActions from '~/work_items/components/work_item_actions.vue';

describe('WorkItemDetailModal component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const findModal = () => wrapper.findComponent(GlModal);
  const findWorkItemActions = () => wrapper.findComponent(WorkItemActions);
  const findWorkItemDetail = () => wrapper.findComponent(WorkItemDetail);

  const createComponent = ({ visible = true, workItemId = '1', canUpdate = false } = {}) => {
    wrapper = shallowMount(WorkItemDetailModal, {
      propsData: { visible, workItemId, canUpdate },
      stubs: {
        GlModal,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each([true, false])('when visible=%s', (visible) => {
    it(`${visible ? 'renders' : 'does not render'} modal`, () => {
      createComponent({ visible });

      expect(findModal().props('visible')).toBe(visible);
    });
  });

  it('renders heading', () => {
    createComponent();

    expect(wrapper.find('h2').text()).toBe('Work Item');
  });

  it('renders WorkItemDetail', () => {
    createComponent();

    expect(findWorkItemDetail().props()).toEqual({ workItemId: '1' });
  });

  it('shows work item actions', () => {
    createComponent({
      canUpdate: true,
    });

    expect(findWorkItemActions().exists()).toBe(true);
  });
});
