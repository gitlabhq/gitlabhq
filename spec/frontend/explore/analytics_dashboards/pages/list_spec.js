import { GlTabs } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ExploreAnalyticsDashboardsList from '~/explore/analytics_dashboards/pages/list.vue';
import DashboardListTab from '~/explore/analytics_dashboards/components/dashboard_list_tab.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';

describe('ExploreAnalyticsDashboardsList', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ExploreAnalyticsDashboardsList);
  };

  const findTabs = () => wrapper.findComponent(GlTabs);
  const findDashboardListTabs = () => wrapper.findAllComponents(DashboardListTab);
  const findPageHeading = () => wrapper.findComponent(PageHeading);

  describe('renders the main layout', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the tabs component', () => {
      expect(findTabs().exists()).toBe(true);
    });

    it('renders one dashboard list tab', () => {
      expect(findDashboardListTabs()).toHaveLength(1);
    });

    it('renders the page heading with the title', () => {
      expect(findPageHeading().exists()).toBe(true);
      expect(findPageHeading().props('heading')).toBe('Analytics dashboards');
    });

    it('renders the page heading description', () => {
      expect(findPageHeading().text()).toContain(
        'Keep your teams aligned around the metrics that matter most.',
      );
    });
  });

  describe('dashboard list tabs', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the "Created by GitLab" tab with GITLAB scope', () => {
      const tab = findDashboardListTabs().at(0);
      expect(tab.props('scope')).toBe('GITLAB');
    });
  });
});
