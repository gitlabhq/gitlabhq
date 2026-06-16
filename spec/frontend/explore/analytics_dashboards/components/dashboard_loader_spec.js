import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlSkeletonLoader, GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import DashboardLoader from '~/explore/analytics_dashboards/components/dashboard_loader.vue';
import getDashboardQuery from '~/explore/analytics_dashboards/graphql/get_dashboard.query.graphql';
import getSystemDashboardQuery from '~/explore/analytics_dashboards/graphql/get_system_dashboard.query.graphql';
import * as sentryBrowserWrapper from '~/sentry/sentry_browser_wrapper';
import {
  mockDashboardResponse,
  mockDashboardCompactGridResponse,
  mockSystemDashboardResponse,
} from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/sentry/sentry_browser_wrapper');

describe('DashboardLoader', () => {
  let wrapper;

  const mockBreadcrumbState = { name: '', slug: '', update: jest.fn() };

  const mockResolvedQuery = (queryResponse = mockDashboardResponse) =>
    createMockApollo([[getDashboardQuery, jest.fn().mockResolvedValue({ data: queryResponse })]]);

  const mockRejectedQuery = () =>
    createMockApollo([
      [getDashboardQuery, jest.fn().mockRejectedValue(new Error('Network error'))],
    ]);

  const createComponent = ({ requestHandlers, routeParams = { slug: '3' }, stubs = {} } = {}) => {
    wrapper = shallowMountExtended(DashboardLoader, {
      apolloProvider: requestHandlers || mockResolvedQuery(),
      provide: { breadcrumbState: mockBreadcrumbState },
      mocks: { $route: { params: routeParams } },
      stubs,
      scopedSlots: {
        dashboard: `
          <div data-testid="dashboard-slot">
            <div data-testid="slot-dashboard-id">{{ props.dashboardId }}</div>
            <div data-testid="slot-config">{{ JSON.stringify(props.config) }}</div>
            <div data-testid="slot-cellHeight">{{ props.cellHeight }}</div>
            <div data-testid="slot-minCellHeight">{{ props.minCellHeight }}</div>
            <div data-testid="slot-hasPanels">{{ props.hasPanels }}</div>
            <div data-testid="slot-isSystemDashboard">{{ props.isSystemDashboard }}</div>
          </div>
        `,
      },
    });
  };

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findDashboardSlot = () => wrapper.findByTestId('dashboard-slot');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const getSlotProp = (name) => {
    const value = wrapper.findByTestId(`slot-${name}`).text();
    return name === 'config' ? JSON.parse(value) : value;
  };

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('while the query is loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('does not render the dashboard slot', () => {
      expect(findDashboardSlot().exists()).toBe(false);
    });
  });

  describe('with data loaded', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('does not render the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });

    it('renders the dashboard slot', () => {
      expect(findDashboardSlot().exists()).toBe(true);
    });

    it('updates the breadcrumb state with the dashboard title and slug', () => {
      expect(mockBreadcrumbState.update).toHaveBeenCalledWith({
        name: 'Fake trend dashboard',
        slug: '3',
      });
    });

    it('replaces original panel ids with unique ids', () => {
      const { panels } = getSlotProp('config');

      panels.forEach((panel, idx) => {
        expect(panel.id).toBe(`panel-${idx + 1}`);
        expect(panel.id).not.toBe(`panel-original-${idx + 1}`);
      });
    });

    it('passes the dashboard ID to the slot', () => {
      expect(getSlotProp('dashboard-id')).toBe(
        'gid://gitlab/Analytics::CustomDashboards::Dashboard/3',
      );
    });

    it('passes cellHeight to the slot for a non-compact grid', () => {
      expect(getSlotProp('cellHeight')).toBe('');
    });

    it('passes minCellHeight to the slot for a non-compact grid', () => {
      expect(getSlotProp('minCellHeight')).toBe('');
    });

    it('passes hasPanels as true to the slot when dashboard has panels', () => {
      expect(getSlotProp('hasPanels')).toBe('true');
    });

    it('passes isSystemDashboard as false to the slot for a custom dashboard', () => {
      expect(getSlotProp('isSystemDashboard')).toBe('false');
    });
  });

  describe('with a compact grid height', () => {
    beforeEach(async () => {
      createComponent({ requestHandlers: mockResolvedQuery(mockDashboardCompactGridResponse) });
      await waitForPromises();
    });

    it('passes cellHeight as 10 to the slot', () => {
      expect(getSlotProp('cellHeight')).toBe('10');
    });

    it('passes minCellHeight as 10 to the slot', () => {
      expect(getSlotProp('minCellHeight')).toBe('10');
    });
  });

  describe('with a query error', () => {
    beforeEach(async () => {
      createComponent({ requestHandlers: mockRejectedQuery() });
      await waitForPromises();
    });

    it('does not render the dashboard slot', () => {
      expect(findDashboardSlot().exists()).toBe(false);
    });

    it('shows an error alert', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toBe('Failed to load dashboard. Please try again.');
    });

    it('logs the error to sentry', () => {
      expect(sentryBrowserWrapper.captureException).toHaveBeenCalledWith(expect.any(Error));
    });
  });

  describe('when the route is a system dashboard', () => {
    let customQueryHandler;
    let systemQueryHandler;

    const createSystemComponent = ({ slug = 'merge_requests' } = {}) => {
      customQueryHandler = jest.fn().mockResolvedValue({ data: mockDashboardResponse });
      systemQueryHandler = jest.fn().mockResolvedValue({ data: mockSystemDashboardResponse });

      const apolloProvider = createMockApollo([
        [getDashboardQuery, customQueryHandler],
        [getSystemDashboardQuery, systemQueryHandler],
      ]);

      createComponent({
        requestHandlers: apolloProvider,
        routeParams: { slug },
      });
    };

    beforeEach(async () => {
      createSystemComponent();
      await waitForPromises();
    });

    it('uses the system dashboard query', () => {
      expect(systemQueryHandler).toHaveBeenCalledWith({ slug: 'merge_requests' });
    });

    it('does not call the custom dashboard query', () => {
      expect(customQueryHandler).not.toHaveBeenCalled();
    });

    it('does not convert the slug into a GraphQL ID', () => {
      expect(systemQueryHandler).not.toHaveBeenCalledWith(
        expect.objectContaining({ slug: expect.stringContaining('gid://') }),
      );
    });

    it('passes the dashboard slug to the slot as the ID', () => {
      expect(getSlotProp('dashboard-id')).toEqual('merge_requests');
    });

    it('renders the system dashboard config in the slot', () => {
      expect(getSlotProp('config')).toMatchObject(
        mockSystemDashboardResponse.customSystemDashboard.config,
      );
    });

    it('passes isSystemDashboard as true to the slot', () => {
      expect(getSlotProp('isSystemDashboard')).toBe('true');
    });
  });

  describe('when the system dashboard does not exist', () => {
    let systemQueryHandler;

    beforeEach(async () => {
      systemQueryHandler = jest.fn().mockResolvedValue({ data: { customSystemDashboard: null } });

      const apolloProvider = createMockApollo([[getSystemDashboardQuery, systemQueryHandler]]);

      createComponent({
        requestHandlers: apolloProvider,
        routeParams: { slug: 'does_not_exist' },
      });

      await waitForPromises();
    });

    it('queries the system dashboard endpoint with the slug', () => {
      expect(systemQueryHandler).toHaveBeenCalledWith({ slug: 'does_not_exist' });
    });

    it('does not show an error alert', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('renders the dashboard slot with an empty config', () => {
      expect(findDashboardSlot().exists()).toBe(true);
      expect(getSlotProp('config')).toEqual({});
    });
  });

  describe('empty dashboard', () => {
    beforeEach(async () => {
      const emptyDashboardResponse = {
        customDashboard: {
          ...mockDashboardResponse.customDashboard,
          config: {
            ...mockDashboardResponse.customDashboard.config,
            panels: [],
          },
        },
      };

      createComponent({ requestHandlers: mockResolvedQuery(emptyDashboardResponse) });
      await waitForPromises();
    });

    it('passes hasPanels as false to the slot when dashboard has no panels', () => {
      expect(getSlotProp('hasPanels')).toBe('false');
    });
  });
});
