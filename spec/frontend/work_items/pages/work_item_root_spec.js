import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';
import WorkItemsRoot from '~/work_items/pages/work_item_root.vue';

Vue.use(VueApollo);

describe('Work items root component', () => {
  let wrapper;

  const findWorkItemDetail = () => wrapper.findComponent(WorkItemDetail);

  const createComponent = () => {
    wrapper = shallowMount(WorkItemsRoot, {
      propsData: {
        id: '1',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders WorkItemDetail', () => {
    createComponent();

    expect(findWorkItemDetail().props()).toEqual({ workItemId: 'gid://gitlab/WorkItem/1' });
  });
});
