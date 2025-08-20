import { shallowMount } from '@vue/test-utils';

import WorkItemParentToken from '~/vue_shared/components/filtered_search_bar/tokens/work_item_parent_token.vue';

describe('WorkItemParentToken', () => {
  let wrapper;

  const createComponent = ({ config = {}, value = { data: '' }, active = false } = {}) => {
    wrapper = shallowMount(WorkItemParentToken, {
      propsData: {
        config,
        value,
        active,
      },
    });
  };

  it('renders the component', () => {
    createComponent();

    expect(wrapper.findComponent(WorkItemParentToken).exists()).toBe(true);
  });
});
