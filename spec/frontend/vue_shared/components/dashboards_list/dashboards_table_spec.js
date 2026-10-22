import { GlAvatarLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import DashboardsTable from '~/vue_shared/components/dashboards_list/dashboards_table.vue';
import DashboardsListItemActions from 'ee_else_ce/vue_shared/components/dashboards_list/dashboards_list_item_actions.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

const mockCustomDashboard = {
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
  updatedAt: '2020-07-01T00:00:00Z',
  dashboardUrl: '/fake/url/1',
};

const mockSystemDashboard = {
  id: 'gitlab:dashboard:system-dashboard',
  name: 'System dashboard',
  description: 'Dashboard created and maintained by GitLab',
  slug: 'system-dashboard',
  system: true,
  dashboardUrl: '/fake/url/system',
};

describe('DashboardsTable', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const findRows = () => wrapper.findAll('tbody tr');
  const findRow = (index) => findRows().at(index);
  const findHeaders = () => wrapper.findAll('thead th').wrappers.map((th) => th.text());

  const createWrapper = (dashboards = [mockCustomDashboard, mockSystemDashboard]) => {
    wrapper = mountExtended(DashboardsTable, {
      propsData: { dashboards },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  it('labels the columns, keeping the actions header for screen readers only', () => {
    expect(findHeaders()).toEqual(['Title', 'Created by', 'Last edited', 'Actions']);
    expect(wrapper.find('thead th:last-child .gl-sr-only').text()).toBe('Actions');
  });

  it('labels stacked cells except the actions menu, which names itself', () => {
    const labels = findRow(0)
      .findAll('td')
      .wrappers.map((td) => td.attributes('data-label'));

    expect(labels).toEqual(['Title', 'Created by', 'Last edited', '']);
  });

  it('names the table for screen readers', () => {
    expect(wrapper.find('table').attributes('aria-label')).toBe('Dashboards');
  });

  it('renders a row for each dashboard', () => {
    expect(findRows()).toHaveLength(2);
  });

  it('links each dashboard name to its dashboard', () => {
    const link = findRow(0).find('[data-testid="dashboard-redirect-link"]');

    expect(link.text()).toBe(mockCustomDashboard.name);
    expect(link.attributes('href')).toBe(mockCustomDashboard.dashboardUrl);
    expect(findRow(0).text()).toContain(mockCustomDashboard.description);
  });

  describe('with a custom dashboard', () => {
    it('links the creator to their profile', () => {
      const avatarLink = findRow(0).findComponent(GlAvatarLink);

      expect(avatarLink.attributes('href')).toBe(mockCustomDashboard.createdBy.webPath);
      expect(avatarLink.attributes('aria-label')).toBe('Created by Fake User');
    });

    it('renders when it was last edited', () => {
      expect(findRow(0).findComponent(TimeAgoTooltip).props('time')).toBe(
        mockCustomDashboard.updatedAt,
      );
    });

    it('announces the last edited time as a full sentence', () => {
      const time = findRow(0).find('[data-testid="dashboard-updated-at"]');

      expect(time.attributes('aria-label')).toBe(`Last edited ${time.text()}`);
    });
  });

  describe('with a custom dashboard whose creator was deleted', () => {
    beforeEach(() => {
      createWrapper([{ ...mockCustomDashboard, createdBy: null }, mockSystemDashboard]);
    });

    it('hides the empty created by cell only when the table is stacked', () => {
      const createdByCell = (index) => findRow(index).findAll('td').at(1);

      expect(createdByCell(0).text()).toBe('');
      expect(createdByCell(0).classes()).toContain('@max-md/panel:!gl-hidden');
      expect(createdByCell(1).classes()).not.toContain('@max-md/panel:!gl-hidden');
    });
  });

  describe('with a system dashboard', () => {
    it('attributes the dashboard to GitLab', () => {
      expect(findRow(1).find('[data-testid="dashboards-list-authorship"]').text()).toBe(
        'Created by GitLab',
      );
    });

    it('does not render a last edited time', () => {
      expect(findRow(1).findComponent(TimeAgoTooltip).exists()).toBe(false);
    });

    it('hides the empty last edited cell only when the table is stacked', () => {
      const lastEditedCell = (index) => findRow(index).findAll('td').at(2);

      expect(lastEditedCell(1).classes()).toContain('@max-md/panel:!gl-hidden');
      expect(lastEditedCell(0).classes()).not.toContain('@max-md/panel:!gl-hidden');
    });
  });

  describe('with names that contain HTML characters', () => {
    beforeEach(() => {
      createWrapper([
        {
          ...mockCustomDashboard,
          name: 'Issues & MRs',
          createdBy: { ...mockCustomDashboard.createdBy, name: 'Tom & Jerry' },
        },
      ]);
    });

    it('does not escape them in the accessible names', () => {
      expect(findRow(0).findComponent(DashboardsListItemActions).props('actionLabel')).toBe(
        'More actions for Issues & MRs',
      );
      expect(findRow(0).findComponent(GlAvatarLink).attributes('aria-label')).toBe(
        'Created by Tom & Jerry',
      );
    });
  });

  it.each`
    index | dashboard
    ${0}  | ${mockCustomDashboard}
    ${1}  | ${mockSystemDashboard}
  `('renders row actions for $dashboard.name', ({ index, dashboard }) => {
    const row = findRow(index);

    expect(row.findComponent(DashboardsListItemActions).props('actionLabel')).toBe(
      `More actions for ${dashboard.name}`,
    );
    expect(row.find('[data-testid="dashboard-open-action"] a').attributes('href')).toBe(
      dashboard.dashboardUrl,
    );
  });
});
