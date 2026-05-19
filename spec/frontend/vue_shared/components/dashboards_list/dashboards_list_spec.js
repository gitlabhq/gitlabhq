import { GlTable, GlAvatarLabeled } from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import DashboardsList from '~/vue_shared/components/dashboards_list/dashboards_list.vue';

const mockDashboards = [
  {
    name: 'First custom dashboard',
    description: 'Default dashboard description',
    slug: 'first-custom-dashboard',
    createdBy: {
      id: 133737,
      name: 'Fake User',
      username: 'fakeuser',
      avatarUrl: '/fake/user/avatar.jpg',
      webUrl: '/fakeuser',
      webPath: '/fakeuser',
    },
    isCustom: true,
    isStarred: false,
    isEditable: true,
    shareLink: '/fake/link/to/share',
    updatedAt: '2020-07-01',
    dashboardUrl: '/fake/url/1',
  },
  {
    name: 'Cool dashboard',
    description:
      'Cool custom dashboard that has a description that is very long and will most definitely overflow',
    slug: 'cool-custom-dashboard',
    createdBy: {
      id: 133737,
      name: 'Fake User',
      username: 'fakeuser',
      avatarUrl: '/fake/user/avatar.jpg',
      webUrl: '/fakeuser',
      webPath: '/fakeuser',
    },
    isCustom: true,
    isStarred: false,
    isEditable: true,
    shareLink: '/fake/link/to/share',
    updatedAt: '2020-06-01',
    dashboardUrl: '/fake/url/2',
  },
];

describe('DashboardsList', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const findTable = () => wrapper.findComponent(GlTable);
  const findTableRows = () => wrapper.findAll('tbody tr');
  const findStarIcons = () => wrapper.findAllByTestId('dashboard-star-icon');
  const findDashboardLinks = () => wrapper.findAllByTestId('dashboard-redirect-link');
  const findUserAvatars = () => wrapper.findAllComponents(GlAvatarLabeled);
  const findActionDropdowns = () => wrapper.findAllByTestId('dashboard-actions');

  const createWrapper = (props = {}, mountFn = shallowMountExtended) => {
    wrapper = mountFn(DashboardsList, {
      propsData: {
        dashboards: mockDashboards,
        ...props,
      },
    });
  };

  describe('with valid dashboard data', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the table component', () => {
      expect(findTable().exists()).toBe(true);
      expect(findTable().attributes('stacked')).toBe('sm');
    });
  });

  describe('with data', () => {
    describe('with custom dashboards', () => {
      beforeEach(() => {
        createWrapper({}, mountExtended);
      });

      it('renders the correct number of table rows', () => {
        expect(findTableRows()).toHaveLength(mockDashboards.length);
      });

      it('renders user avatars with correct props', () => {
        const avatars = findUserAvatars();

        avatars.wrappers.forEach((avatar, index) => {
          const dashboard = mockDashboards[index];
          expect(avatar.props()).toMatchObject({
            src: dashboard.createdBy.avatarUrl,
            size: 24,
            shape: 'circle',
            fallbackOnError: true,
            label: dashboard.createdBy.name,
          });
        });
      });

      it('renders user', () => {
        mockDashboards.forEach((dashboard, index) => {
          const row = findTableRows().at(index);
          expect(row.text()).toContain(dashboard.createdBy.name);

          expect(row.html()).toContain(dashboard.createdBy.webPath);
        });
      });

      it('renders last edited dates as relative time', () => {
        mockDashboards.forEach((dashboard, index) => {
          const row = findTableRows().at(index);
          const updatedAt = row.find('[data-testid="dashboard-updated-at"]');
          expect(updatedAt.exists()).toBe(true);
        });

        expect(findTableRows().at(0).text()).toContain('5 days ago');
        expect(findTableRows().at(1).text()).toContain('1 month ago');
      });

      it('renders action dropdowns for each dashboard', () => {
        const actionDropdowns = findActionDropdowns();

        expect(actionDropdowns).toHaveLength(mockDashboards.length);

        actionDropdowns.wrappers.forEach((dropdown) => {
          expect(dropdown.props()).toMatchObject({
            icon: 'ellipsis_v',
            category: 'tertiary',
            textSrOnly: true,
            noCaret: true,
          });
        });
      });

      it('renders the valid fields', () => {
        const expectedFields = ['Title', 'Created by', 'Last edited', 'Actions'];
        const fields = findTable()
          .props('fields')
          .map(({ label }) => label);

        expect(fields).toEqual(expectedFields);
      });
    });

    describe('with system dashboards', () => {
      const mockSystemDashboards = [
        {
          name: 'System dashboard',
          system: true,
          description:
            'Cool custom dashboard that has a description that is very long and will most definitely overflow',
          slug: 'cool-custom-dashboard',
          shareLink: '/fake/link/to/share',
          updatedAt: '2025-10-28',
          dashboardUrl: '/fake/url/2',
        },
      ];

      beforeEach(() => {
        createWrapper({ dashboards: mockSystemDashboards }, mountExtended);
      });

      it('renders the correct number of table rows', () => {
        expect(findTableRows()).toHaveLength(mockSystemDashboards.length);
      });

      it('renders GitLab in the created by field', () => {
        const avatars = findUserAvatars();

        avatars.wrappers.forEach((avatar) => {
          expect(avatar.props()).toMatchObject({
            src: 'file-mock',
            size: 24,
            shape: 'circle',
            fallbackOnError: true,
            label: 'GitLab',
          });
        });
      });

      it('renders the valid fields', () => {
        const expectedFields = ['Title', 'Created by', 'Last edited', 'Actions'];
        const fields = findTable()
          .props('fields')
          .map(({ label }) => label);

        expect(fields).toEqual(expectedFields);
      });

      it('does not render the last edited time for system dashboards', () => {
        const updatedAt = findTableRows().at(0).find('[data-testid="dashboard-updated-at"]');
        expect(updatedAt.exists()).toBe(false);
      });
    });
  });

  describe('with empty dashboard data', () => {
    beforeEach(() => {
      createWrapper({ dashboards: [] });
    });

    it('renders the table component', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('renders no table rows', () => {
      expect(findTableRows()).toHaveLength(0);
    });

    it('renders no dashboard links', () => {
      expect(findDashboardLinks()).toHaveLength(0);
    });

    it('renders no star icons', () => {
      expect(findStarIcons()).toHaveLength(0);
    });

    it('renders no user avatars', () => {
      expect(findUserAvatars()).toHaveLength(0);
    });
  });
});
