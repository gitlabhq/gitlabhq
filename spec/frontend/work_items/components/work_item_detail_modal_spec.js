import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';

describe('WorkItemDetailModal component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const findModal = () => wrapper.findComponent(GlModal);
  const findWorkItemDetail = () => wrapper.findComponent(WorkItemDetail);

  const createComponent = ({ visible = true, workItemId = '1' } = {}) => {
    wrapper = shallowMount(WorkItemDetailModal, {
      propsData: { visible, workItemId },
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

  it('renders WorkItemDetail', () => {
    createComponent();

    expect(findWorkItemDetail().props()).toEqual({ workItemId: '1' });
  });
});
