import { GlTabs, GlSearchBoxByType } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ExploreAnalyticsDashboardsList from '~/explore/analytics_dashboards/pages/list.vue';
import DashboardListTab from '~/explore/analytics_dashboards/components/dashboard_list_tab.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import NewDashboardButton from '~/explore/analytics_dashboards/components/new_dashboard_button.vue';

describe('ExploreAnalyticsDashboardsList', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ExploreAnalyticsDashboardsList);
  };

  const findTabs = () => wrapper.findComponent(GlTabs);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findDashboardListTabs = () => wrapper.findAllComponents(DashboardListTab);
  const findPageHeading = () => wrapper.findComponent(PageHeading);
  const findNewDashboardButton = () => wrapper.findComponent(NewDashboardButton);

  describe('renders the main layout', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the tabs component', () => {
      expect(findTabs().exists()).toBe(true);
    });

    it('renders the search box', () => {
      expect(findSearchBox().exists()).toBe(true);
    });

    it('renders three dashboard list tabs', () => {
      expect(findDashboardListTabs()).toHaveLength(3);
    });

    it('renders the page title', () => {
      expect(findPageHeading().props('heading')).toBe('Analytics dashboards');
    });

    it('renders the page description', () => {
      expect(findPageHeading().text()).toContain(
        'Keep your teams aligned around the metrics that matter most.',
      );
    });

    it('renders the new dashboard button', () => {
      expect(findNewDashboardButton().exists()).toBe(true);
    });
  });

  describe('dashboard list tabs', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the "All" tab first without scope filter', () => {
      const tabs = findDashboardListTabs();
      expect(tabs.at(0).props('scope')).toBeNull();
    });

    it('renders the "Created by me" tab second with USER scope', () => {
      const tabs = findDashboardListTabs();
      expect(tabs.at(1).props('scope')).toBe('USER');
    });

    it('renders the "Created by GitLab" tab third with GITLAB scope', () => {
      const tabs = findDashboardListTabs();
      expect(tabs.at(2).props('scope')).toBe('GITLAB');
    });
  });

  describe('search functionality', () => {
    const findAllTabs = () => findDashboardListTabs().wrappers;

    beforeEach(() => {
      createComponent();
    });

    it('does not pass search text to tabs when less than 3 characters', async () => {
      await findSearchBox().vm.$emit('input', 'ab');

      const tabs = findAllTabs();
      tabs.forEach((tab) => {
        expect(tab.props('search')).toBe('');
      });
    });

    it('passes search text to tabs when 3 or more characters', async () => {
      await findSearchBox().vm.$emit('input', 'test');

      const tabs = findAllTabs();
      tabs.forEach((tab) => {
        expect(tab.props('search')).toBe('test');
      });
    });

    it('clears search text when input is cleared', async () => {
      await findSearchBox().vm.$emit('input', 'test');

      let tabs = findAllTabs();
      tabs.forEach((tab) => {
        expect(tab.props('search')).toBe('test');
      });

      await findSearchBox().vm.$emit('input', '');

      tabs = findAllTabs();
      tabs.forEach((tab) => {
        expect(tab.props('search')).toBe('');
      });
    });
  });

  describe('tab management', () => {
    beforeEach(() => {
      createComponent();
    });

    it('defaults to the "All" tab', () => {
      expect(findTabs().props('value')).toBe(0);
    });

    it('updates the active tab when changed', async () => {
      await findTabs().vm.$emit('input', 1);

      expect(findTabs().props('value')).toBe(1);
    });
  });
});
