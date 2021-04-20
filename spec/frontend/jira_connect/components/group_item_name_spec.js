import { shallowMount } from '@vue/test-utils';

import GroupItemName from '~/jira_connect/components/group_item_name.vue';
import { mockGroup1 } from '../mock_data';

describe('GroupItemName', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(GroupItemName, {
      propsData: {
        group: mockGroup1,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    it('matches the snapshot', () => {
      createComponent();

      expect(wrapper.element).toMatchSnapshot();
    });
  });
});
