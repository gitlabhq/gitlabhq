import { shallowMount } from '@vue/test-utils';
import FrequentItems from '~/super_sidebar/components/global_search/components/frequent_items.vue';
import FrequentGroups from '~/super_sidebar/components/global_search/components/frequent_groups.vue';

describe('FrequentlyVisitedGroups', () => {
  let wrapper;

  const groupsPath = '/mock/group/path';

  const createComponent = (options) => {
    wrapper = shallowMount(FrequentGroups, {
      provide: {
        groupsPath,
      },
      ...options,
    });
  };

  const findFrequentItems = () => wrapper.findComponent(FrequentItems);
  const receivedAttrs = (wrapperInstance) => ({
    // See https://github.com/vuejs/test-utils/issues/2151.
    ...wrapperInstance.vm.$attrs,
  });

  it('passes group-specific props', () => {
    createComponent();

    expect(findFrequentItems().props()).toMatchObject({
      emptyStateText: 'Groups you visit often will appear here.',
      groupName: 'Frequently visited groups',
      maxItems: 3,
      storageKey: null,
      viewAllItemsIcon: 'group',
      viewAllItemsText: 'View all my groups',
      viewAllItemsPath: groupsPath,
    });
  });

  it('with a user, passes a storage key string to FrequentItems', () => {
    gon.current_username = 'test_user';
    createComponent();

    expect(findFrequentItems().props('storageKey')).toBe('test_user/frequent-groups');
  });

  it('passes attrs to FrequentItems', () => {
    createComponent({ attrs: { bordered: true, class: 'test-class' } });

    expect(findFrequentItems().classes()).toContain('test-class');
    expect(receivedAttrs(findFrequentItems())).toMatchObject({
      bordered: true,
    });
  });

  it('forwards listeners to FrequentItems', () => {
    const spy = jest.fn();
    createComponent({ listeners: { 'nothing-to-render': spy } });

    findFrequentItems().vm.$emit('nothing-to-render');

    expect(spy).toHaveBeenCalledTimes(1);
  });
});
