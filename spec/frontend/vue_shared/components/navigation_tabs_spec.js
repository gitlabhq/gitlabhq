import { GlTab } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import NavigationTabs from '~/vue_shared/components/navigation_tabs.vue';

describe('navigation tabs component', () => {
  let wrapper;

  const data = [
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

  const createComponent = () => {
    wrapper = mount(NavigationTabs, {
      propsData: {
        tabs: data,
        scope: 'pipelines',
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('should render tabs', () => {
    expect(wrapper.findAllComponents(GlTab)).toHaveLength(data.length);
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
