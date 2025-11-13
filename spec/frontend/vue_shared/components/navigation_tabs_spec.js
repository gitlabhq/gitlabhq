import { GlLoadingIcon, GlTab } from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NavigationTabs from '~/vue_shared/components/navigation_tabs.vue';

describe('navigation tabs component', () => {
  let wrapper;

  const defaultTabs = [
    {
      name: 'All',
      scope: 'all',
      count: 1,
      isActive: true,
    },
    {
      name: 'Pending',
      scope: 'pending',
      count: 0,
      isActive: false,
    },
    {
      name: 'Running',
      scope: 'running',
      isActive: false,
    },
  ];

  const findAllLoadingIcons = () => wrapper.findAllComponents(GlLoadingIcon);

  const createComponent = (mountFn = mountExtended, tabs = defaultTabs) => {
    wrapper = mountFn(NavigationTabs, {
      propsData: {
        tabs,
        scope: 'pipelines',
      },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should render tabs', () => {
      expect(wrapper.findAllComponents(GlTab)).toHaveLength(defaultTabs.length);
    });

    it('should render active tab', () => {
      expect(wrapper.find('.js-pipelines-tab-all').classes('active')).toBe(true);
    });

    it('should render badge', () => {
      expect(wrapper.find('.js-pipelines-tab-all').text()).toContain('1');
      expect(wrapper.find('.js-pipelines-tab-pending').text()).toContain('0');
    });

    it('should not render badge', () => {
      expect(wrapper.find('.js-pipelines-tab-running .badge').exists()).toBe(false);
    });

    it('should trigger onTabClick', async () => {
      await wrapper.find('.js-pipelines-tab-pending').trigger('click');

      expect(wrapper.emitted('onChangeTab')).toEqual([['pending']]);
    });
  });

  describe('loading', () => {
    it('should display loading icon', () => {
      const tabs = [
        {
          name: 'All',
          scope: 'all',
          count: 1,
          isActive: true,
          isLoading: true,
        },
        {
          name: 'Pending',
          scope: 'pending',
          isActive: false,
        },
      ];

      createComponent(shallowMountExtended, tabs);

      const loadingIcons = findAllLoadingIcons();
      expect(loadingIcons).toHaveLength(1);
      expect(loadingIcons.at(0).exists()).toBe(true);
    });

    it('does not display loading icon', () => {
      createComponent(shallowMountExtended);

      expect(findAllLoadingIcons()).toHaveLength(0);
    });
  });
});
