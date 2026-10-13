import { GlAvatarLabeled, GlAvatarLink } from '@gitlab/ui';
import GITLAB_LOGO_SVG_URL from '@gitlab/svgs/dist/illustrations/gitlab_logo.svg?url';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { assertProps } from 'helpers/assert_props';
import DashboardCard from '~/vue_shared/components/dashboards_list/dashboard_card.vue';
import DashboardCardThumbnail from '~/vue_shared/components/dashboards_list/dashboard_card_thumbnail.vue';
import DashboardsListItemActions from 'ee_else_ce/vue_shared/components/dashboards_list/dashboards_list_item_actions.vue';

const mockCustomDashboard = {
  id: 'gid://gitlab/Analytics::CustomDashboard/1',
  name: 'First custom dashboard',
  description: 'Default dashboard description',
  slug: 'first-custom-dashboard',
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

describe('DashboardCard', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const findDashboardLink = () => wrapper.findByTestId('dashboard-redirect-link');
  const findThumbnail = () => wrapper.findByTestId('dashboard-card-thumbnail');
  const findUpdatedAt = () => wrapper.findByTestId('dashboard-updated-at');
  const findThumbnailComponent = () => wrapper.findComponent(DashboardCardThumbnail);
  const findAvatar = () => wrapper.findComponent(GlAvatarLabeled);
  const findAvatarLink = () => wrapper.findComponent(GlAvatarLink);
  const findActions = () => wrapper.findComponent(DashboardsListItemActions);
  const findActionsWrapper = () => wrapper.findByTestId('dashboard-card-actions');

  const createWrapper = ({ dashboard = mockCustomDashboard } = {}) => {
    wrapper = mountExtended(DashboardCard, {
      propsData: {
        dashboard,
      },
    });
  };

  describe('with a custom dashboard', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders a link to the dashboard', () => {
      expect(findDashboardLink().text()).toBe(mockCustomDashboard.name);
      expect(findDashboardLink().attributes('href')).toBe(mockCustomDashboard.dashboardUrl);
    });

    it('renders the dashboard description', () => {
      expect(wrapper.text()).toContain(mockCustomDashboard.description);
    });

    it('names the creator link with a full authorship sentence', () => {
      expect(findAvatarLink().attributes('aria-label')).toBe('Created by Fake User');
      expect(wrapper.findByTestId('dashboard-card-authorship').exists()).toBe(false);
    });

    it('renders the creator avatar with their name, linking to their profile', () => {
      expect(findAvatarLink().attributes('href')).toBe(mockCustomDashboard.createdBy.webPath);
      expect(findAvatar().props()).toMatchObject({
        src: mockCustomDashboard.createdBy.avatarUrl,
        size: 24,
        shape: 'circle',
        fallbackOnError: true,
        label: 'Fake User',
      });
    });

    it('seeds the identicon fallback so a broken avatar image shows a lettered circle', () => {
      expect(findAvatar().props()).toMatchObject({
        entityName: mockCustomDashboard.createdBy.name,
        entityId: 133737,
      });
    });

    it('renders the last updated time as relative time next to the creator', () => {
      expect(findUpdatedAt().find('time').text()).toBe('5 days ago');
      expect(wrapper.text()).toContain('·');
    });

    it('announces the timestamp as a full sentence', () => {
      expect(findUpdatedAt().find('time').attributes('aria-label')).toBe('Updated 5 days ago');
      expect(findUpdatedAt().find('time').attributes('aria-hidden')).toBeUndefined();
    });

    it('stretches the title link over the whole card', () => {
      expect(findDashboardLink().classes()).toContain('gl-stretched-link');
    });

    it('renders the actions dropdown with a per-card accessible name', () => {
      expect(findActions().props()).toMatchObject({
        actionLabel: 'More actions for First custom dashboard',
      });
    });

    it('renders the actions dropdown outside the clipped thumbnail', () => {
      expect(findActionsWrapper().exists()).toBe(true);
      expect(findThumbnail().find('[data-testid="dashboard-card-actions"]').exists()).toBe(false);
    });

    it('renders the name before the actions in DOM order for tab and screen-reader flow', () => {
      const position = findDashboardLink().element.compareDocumentPosition(
        findActionsWrapper().element,
      );

      // eslint-disable-next-line no-bitwise
      expect(Boolean(position & Node.DOCUMENT_POSITION_FOLLOWING)).toBe(true);
    });

    it('renders a decorative thumbnail hidden from screen readers', () => {
      expect(findThumbnail().attributes('aria-hidden')).toBe('true');
    });
  });

  describe('with a custom dashboard whose creator was deleted', () => {
    beforeEach(() => {
      createWrapper({ dashboard: { ...mockCustomDashboard, createdBy: null } });
    });

    it('renders the card without a creator', () => {
      expect(findDashboardLink().text()).toBe(mockCustomDashboard.name);
      expect(findAvatarLink().exists()).toBe(false);
      expect(findAvatar().exists()).toBe(false);
    });

    it('does not announce authorship when there is no creator to name', () => {
      expect(wrapper.findByTestId('dashboard-card-authorship').exists()).toBe(false);
      expect(wrapper.text()).not.toContain('Created by');
    });

    it('still renders the last updated time, without a leading separator', () => {
      expect(findUpdatedAt().find('time').text()).toBe('5 days ago');
      expect(wrapper.text()).not.toContain('·');
    });
  });

  describe('with a system dashboard', () => {
    beforeEach(() => {
      createWrapper({ dashboard: mockSystemDashboard });
    });

    it('renders a link to the dashboard', () => {
      expect(findDashboardLink().text()).toBe(mockSystemDashboard.name);
      expect(findDashboardLink().attributes('href')).toBe(mockSystemDashboard.dashboardUrl);
    });

    it('announces authorship as a visually hidden sentence and hides the decorative avatar', () => {
      expect(wrapper.findByTestId('dashboard-card-authorship').text()).toBe('Created by GitLab');
      expect(findAvatar().element.closest('[aria-hidden="true"]')).not.toBeNull();
    });

    it('renders a GitLab label without a profile link', () => {
      expect(findAvatarLink().exists()).toBe(false);
      expect(findAvatar().props()).toMatchObject({
        src: GITLAB_LOGO_SVG_URL,
        size: 24,
        shape: 'circle',
        fallbackOnError: true,
        label: 'GitLab',
        entityName: 'GitLab',
      });
    });

    it('does not render an updated timestamp or separator', () => {
      expect(findUpdatedAt().exists()).toBe(false);
      expect(wrapper.text()).not.toContain('·');
    });

    it('renders the actions dropdown flagged as a system dashboard', () => {
      expect(findActions().props()).toMatchObject({
        actionLabel: 'More actions for System dashboard',
      });
    });
  });

  describe('dashboard prop contract', () => {
    it.each`
      description             | dashboard
      ${'a custom dashboard'} | ${mockCustomDashboard}
      ${'a system dashboard'} | ${mockSystemDashboard}
    `('accepts $description with the required fields', ({ dashboard }) => {
      expect(() => assertProps(DashboardCard, { dashboard })).not.toThrow();
    });

    // Vue 3 dedupes identical prop-warning messages, so only the first
    // assertProps().toThrow() in a table would throw. Keep one mount-level
    // case and assert the remaining shapes against the validator directly.
    it('rejects a dashboard with a missing id', () => {
      expect(() =>
        assertProps(DashboardCard, { dashboard: { ...mockCustomDashboard, id: undefined } }),
      ).toThrow();
    });

    it.each`
      description                 | dashboard
      ${'a missing name'}         | ${{ ...mockCustomDashboard, name: undefined }}
      ${'a missing dashboardUrl'} | ${{ ...mockCustomDashboard, dashboardUrl: undefined }}
      ${'a non-boolean system'}   | ${{ ...mockCustomDashboard, system: undefined }}
    `('fails validation for a dashboard with $description', ({ dashboard }) => {
      expect(DashboardCard.props.dashboard.validator(dashboard)).toBe(false);
    });

    it('passes validation for a dashboard with the required fields', () => {
      expect(DashboardCard.props.dashboard.validator(mockCustomDashboard)).toBe(true);
    });
  });

  describe('thumbnail seed key', () => {
    it.each`
      description                            | dashboard                                         | seedKey
      ${'a custom dashboard with a slug'}    | ${mockCustomDashboard}                            | ${mockCustomDashboard.slug}
      ${'a custom dashboard without a slug'} | ${{ ...mockCustomDashboard, slug: null }}         | ${mockCustomDashboard.id}
      ${'a system dashboard'}                | ${{ ...mockSystemDashboard, slug: 'dap_impact' }} | ${'dap_impact'}
      ${'a system dashboard without a slug'} | ${{ ...mockSystemDashboard, slug: null }}         | ${mockSystemDashboard.id}
    `('seeds the thumbnail with $description', ({ dashboard, seedKey }) => {
      createWrapper({ dashboard });

      expect(findThumbnailComponent().props('seedKey')).toBe(seedKey);
    });
  });

  describe('thumbnail mimic pieces', () => {
    const configWithPanels = {
      panels: [
        {
          title: 'Total users',
          visualization: { type: 'SingleStat', data: {}, options: {} },
          gridAttributes: { yPos: 0, xPos: 0, width: 4, height: 1 },
        },
        {
          title: 'Users over time',
          visualization: { type: 'LineChart', data: {}, options: {} },
          gridAttributes: { yPos: 1, xPos: 0, width: 12, height: 4 },
        },
      ],
    };

    describe('when the dashboard config has panels', () => {
      beforeEach(() => {
        createWrapper({ dashboard: { ...mockCustomDashboard, config: configWithPanels } });
      });

      it('passes pieces derived from the config to the thumbnail', () => {
        expect(findThumbnailComponent().props('pieces')).toEqual([
          { type: 'stat', wide: false },
          { type: 'line-chart', wide: true },
        ]);
      });

      it('renders a thumbnail mimicking the dashboard composition', () => {
        expect(wrapper.findAllByTestId('dashboard-card-thumbnail-stat')).toHaveLength(1);
        expect(wrapper.findAllByTestId('dashboard-card-thumbnail-line-chart')).toHaveLength(1);
      });
    });

    describe('when the dashboard config has no panels yet', () => {
      beforeEach(() => {
        createWrapper({ dashboard: { ...mockCustomDashboard, config: { panels: [] } } });
      });

      it('passes no pieces so the thumbnail stays seeded', () => {
        expect(findThumbnailComponent().props('pieces')).toBe(null);
      });
    });

    describe('when the dashboard config is malformed', () => {
      beforeEach(() => {
        createWrapper({ dashboard: { ...mockCustomDashboard, config: '{not json' } });
      });

      it('falls back to the seeded thumbnail', () => {
        expect(findThumbnailComponent().props('pieces')).toBe(null);
        expect(findThumbnailComponent().props('seedKey')).toBe(mockCustomDashboard.slug);
      });

      it('keeps the thumbnail decorative', () => {
        expect(findThumbnail().attributes('aria-hidden')).toBe('true');
      });
    });
  });
});
