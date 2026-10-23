import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DashboardsList from '~/explore/analytics_dashboards/components/dashboards_list/dashboards_list.vue';
import DashboardCard from '~/explore/analytics_dashboards/components/dashboards_list/dashboard_card.vue';
import DashboardsTable from '~/explore/analytics_dashboards/components/dashboards_list/dashboards_table.vue';

// Custom dashboards have a null slug in production; only their `id` is unique.
const mockDashboards = [
  {
    id: 'gid://gitlab/Analytics::CustomDashboard/1',
    name: 'First custom dashboard',
    description: 'Default dashboard description',
    slug: null,
    system: false,
    createdBy: {
      id: 133737,
      name: 'Fake User',
      username: 'fakeuser',
      avatarUrl: '/fake/user/avatar.jpg',
      webUrl: '/fakeuser',
      webPath: '/fakeuser',
    },
    updatedAt: '2020-07-01',
    dashboardUrl: '/fake/url/1',
  },
  {
    id: 'gid://gitlab/Analytics::CustomDashboard/2',
    name: 'Second custom dashboard',
    description: 'Another dashboard description',
    slug: null,
    system: false,
    createdBy: {
      id: 133737,
      name: 'Fake User',
      username: 'fakeuser',
      avatarUrl: '/fake/user/avatar.jpg',
      webUrl: '/fakeuser',
      webPath: '/fakeuser',
    },
    updatedAt: '2020-07-02',
    dashboardUrl: '/fake/url/2',
  },
  {
    id: 'gitlab:dashboard:system-dashboard',
    name: 'System dashboard',
    description: 'Dashboard created and maintained by GitLab',
    slug: 'system-dashboard',
    system: true,
    dashboardUrl: '/fake/url/system',
  },
];

describe('DashboardsList', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const findGrid = () => wrapper.find('ul[data-testid="dashboards-list"]');
  const findDashboardCards = () => wrapper.findAllComponents(DashboardCard);
  const findTable = () => wrapper.findComponent(DashboardsTable);

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(DashboardsList, {
      propsData: {
        dashboards: mockDashboards,
        ...props,
      },
    });
  };

  describe('default layout', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the dashboards in a table', () => {
      expect(findTable().props('dashboards')).toEqual(mockDashboards);
    });

    it('does not render the grid', () => {
      expect(findGrid().exists()).toBe(false);
      expect(findDashboardCards()).toHaveLength(0);
    });

    it('passes re-ordered dashboards to the table', async () => {
      const reversed = [...mockDashboards].reverse();

      await wrapper.setProps({ dashboards: reversed });

      expect(findTable().props('dashboards')).toEqual(reversed);
    });
  });

  describe('grid layout', () => {
    describe('with dashboards', () => {
      beforeEach(() => {
        createWrapper({ layout: 'grid' });
      });

      it('does not render the table', () => {
        expect(findTable().exists()).toBe(false);
      });

      it('renders a card for each dashboard', () => {
        expect(findDashboardCards()).toHaveLength(mockDashboards.length);
      });

      it('passes each dashboard to its card', () => {
        const cards = findDashboardCards();

        mockDashboards.forEach((dashboard, index) => {
          expect(cards.at(index).props('dashboard')).toEqual(dashboard);
        });
      });

      it('keeps cards in sync when the list is re-ordered', async () => {
        const reversed = [...mockDashboards].reverse();

        await wrapper.setProps({ dashboards: reversed });

        const cards = findDashboardCards();
        reversed.forEach((dashboard, index) => {
          expect(cards.at(index).props('dashboard')).toEqual(dashboard);
        });
      });
    });

    describe('with empty dashboard data', () => {
      beforeEach(() => {
        createWrapper({ dashboards: [], layout: 'grid' });
      });

      it('renders the list container', () => {
        expect(findGrid().exists()).toBe(true);
      });

      it('renders no cards', () => {
        expect(findDashboardCards()).toHaveLength(0);
      });
    });
  });
});
