import { shallowMount } from '@vue/test-utils';
import FrequentItems from '~/super_sidebar/components/global_search/components/frequent_items.vue';
import FrequentProjects from '~/super_sidebar/components/global_search/components/frequent_projects.vue';

describe('FrequentlyVisitedProjects', () => {
  let wrapper;

  const projectsPath = '/mock/project/path';

  const createComponent = (options) => {
    wrapper = shallowMount(FrequentProjects, {
      provide: {
        projectsPath,
      },
      ...options,
    });
  };

  const findFrequentItems = () => wrapper.findComponent(FrequentItems);
  const receivedAttrs = (wrapperInstance) => ({
    // See https://github.com/vuejs/test-utils/issues/2151.
    ...wrapperInstance.vm.$attrs,
  });

  it('passes project-specific props', () => {
    createComponent();

    expect(findFrequentItems().props()).toMatchObject({
      emptyStateText: 'Projects you visit often will appear here.',
      groupName: 'Frequently visited projects',
      maxItems: 5,
      storageKey: null,
      viewAllItemsIcon: 'project',
      viewAllItemsText: 'View all my projects',
      viewAllItemsPath: projectsPath,
    });
  });

  it('with a user, passes a storage key string to FrequentItems', () => {
    gon.current_username = 'test_user';
    createComponent();

    expect(findFrequentItems().props('storageKey')).toBe('test_user/frequent-projects');
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
