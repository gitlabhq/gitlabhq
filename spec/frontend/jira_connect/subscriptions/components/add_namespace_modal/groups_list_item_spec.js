import { GlButton } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';

import GroupItemName from '~/jira_connect/subscriptions/components/group_item_name.vue';
import GroupsListItem from '~/jira_connect/subscriptions/components/add_namespace_modal/groups_list_item.vue';
import createStore from '~/jira_connect/subscriptions/store';
import { mockGroup1 } from '../../mock_data';

describe('GroupsListItem', () => {
  let wrapper;
  let store;

  const createComponent = ({ mountFn = shallowMount, provide } = {}) => {
    store = createStore();

    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = mountFn(GroupsListItem, {
      store,
      propsData: {
        group: mockGroup1,
      },
      provide: {
        ...provide,
      },
    });
  };

  const findGroupItemName = () => wrapper.findComponent(GroupItemName);
  const findLinkButton = () => wrapper.findComponent(GlButton);
  const clickLinkButton = () => findLinkButton().trigger('click');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders GroupItemName', () => {
      expect(findGroupItemName().exists()).toBe(true);
      expect(findGroupItemName().props('group')).toBe(mockGroup1);
    });

    it('renders Link button', () => {
      expect(findLinkButton().exists()).toBe(true);
      expect(findLinkButton().text()).toBe('Link');
    });
  });

  describe('on Link button click', () => {
    const mockSubscriptionsPath = '/subscriptions';

    beforeEach(() => {
      createComponent({
        mountFn: mount,
        provide: {
          subscriptionsPath: mockSubscriptionsPath,
        },
      });
    });

    it('dispatches `addSubscription` action', () => {
      clickLinkButton();

      expect(store.dispatch).toHaveBeenCalledTimes(1);
      expect(store.dispatch).toHaveBeenCalledWith('addSubscription', {
        namespacePath: mockGroup1.full_path,
        subscriptionsPath: mockSubscriptionsPath,
      });
    });
  });
});
