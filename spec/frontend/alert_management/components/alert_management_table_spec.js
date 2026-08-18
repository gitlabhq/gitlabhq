import {
  GlTable,
  GlAlert,
  GlLoadingIcon,
  GlDisclosureDropdown,
  GlAvatar,
  GlLink,
} from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import mockAlerts from 'jest/vue_shared/alert_details/mocks/alerts.json';
import AlertManagementTable from '~/alert_management/components/alert_management_table.vue';
import getAlertsQuery from '~/graphql_shared/queries/get_alerts.query.graphql';
import getAlertsCountByStatus from '~/alert_management/graphql/queries/get_count_by_status.query.graphql';
import { visitUrl } from '~/lib/utils/url_utility';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import defaultProvideValues from '../mocks/alerts_provide_config.json';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrlMock'),
  joinPaths: jest.requireActual('~/lib/utils/url_utility').joinPaths,
  setUrlFragment: jest.requireActual('~/lib/utils/url_utility').setUrlFragment,
  isAbsolute: jest.requireActual('~/lib/utils/url_utility').isAbsolute,
}));

Vue.use(VueApollo);

const buildAssignees = (assignees) => {
  const nodes = (assignees && assignees.nodes) || [];

  return {
    __typename: 'UserCoreConnection',
    nodes: nodes.map((assignee, index) => ({
      __typename: 'UserCore',
      id: `gid://gitlab/User/${index + 1}`,
      avatarUrl: null,
      name: null,
      username: null,
      webUrl: null,
      webPath: null,
      ...assignee,
    })),
  };
};

const buildIssue = (issue) => {
  if (!issue) {
    return null;
  }

  return {
    __typename: 'Issue',
    id: 'gid://gitlab/Issue/1',
    iid: null,
    state: 'opened',
    title: null,
    webUrl: null,
    ...issue,
  };
};

const buildAlertNodes = (list) =>
  list.map((alert, index) => {
    const { isNew, ...alertFields } = alert;

    return {
      __typename: 'AlertManagementAlert',
      id: `gid://gitlab/AlertManagement::Alert/${index + 1}`,
      iid: null,
      title: null,
      severity: 'CRITICAL',
      status: 'TRIGGERED',
      startedAt: null,
      eventCount: 0,
      ...alertFields,
      ...(isNew ? { startedAt: new Date().toISOString() } : {}),
      issue: buildIssue(alertFields.issue),
      assignees: buildAssignees(alertFields.assignees),
    };
  });

const buildAlertsResponse = (list) => ({
  data: {
    project: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/1',
      alertManagementAlerts: {
        __typename: 'AlertManagementAlertConnection',
        nodes: buildAlertNodes(list),
        pageInfo: {
          __typename: 'PageInfo',
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: null,
          endCursor: null,
        },
      },
    },
  },
});

const buildAlertsCountResponse = ({
  open = 0,
  triggered = 0,
  acknowledged = 0,
  resolved = 0,
  all = 0,
} = {}) => ({
  data: {
    project: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/1',
      alertManagementAlertStatusCounts: {
        __typename: 'AlertManagementAlertStatusCountsType',
        open,
        triggered,
        acknowledged,
        resolved,
        all,
      },
    },
  },
});

const neverResolve = () => jest.fn().mockReturnValue(new Promise(() => {}));

describe('AlertManagementTable', () => {
  let wrapper;
  let mock;

  const findAlertsTable = () => wrapper.findComponent(GlTable);
  const findAlerts = () => wrapper.findAllComponents('table tbody tr');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLoader = () => wrapper.findComponent(GlLoadingIcon);
  const findStatusDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDateFields = () => wrapper.findAllComponents(TimeAgo);
  const findSearch = () => wrapper.findComponent(FilteredSearchBar);
  const findSeverityColumnHeader = () => wrapper.findByTestId('alert-management-severity-sort');
  const findFirstIDField = () => wrapper.findAllByTestId('idField').at(0);
  const findFirstIDLink = () => wrapper.findAllByTestId('idField').at(0).findComponent(GlLink);
  const findAssignees = () => wrapper.findAllByTestId('assigneesField');
  const findSeverityFields = () => wrapper.findAllByTestId('severityField');
  const findIssueFields = () => wrapper.findAllByTestId('issueField');
  const alertsCount = {
    open: 24,
    triggered: 20,
    acknowledged: 16,
    resolved: 11,
    all: 26,
  };

  async function mountComponent({ provide = {}, data = {}, loading = false, stubs = {} } = {}) {
    const {
      alerts = {},
      alertsCount: injectedCount,
      errored,
      isErrorAlertDismissed,
      searchTerm,
      assigneeUsername,
      sort,
    } = data;
    const alertsList = alerts.list || [];

    let alertsHandler;
    let alertsCountHandler;

    if (loading) {
      alertsHandler = neverResolve();
      alertsCountHandler = neverResolve();
    } else if (errored) {
      alertsHandler = jest.fn().mockRejectedValue(new Error('error'));
      alertsCountHandler = jest
        .fn()
        .mockResolvedValue(buildAlertsCountResponse(injectedCount || {}));
    } else {
      alertsHandler = jest.fn().mockResolvedValue(buildAlertsResponse(alertsList));
      alertsCountHandler = jest
        .fn()
        .mockResolvedValue(buildAlertsCountResponse(injectedCount || {}));
    }

    wrapper = extendedWrapper(
      mount(AlertManagementTable, {
        apolloProvider: createMockApollo([
          [getAlertsQuery, alertsHandler],
          [getAlertsCountByStatus, alertsCountHandler],
        ]),
        provide: {
          ...defaultProvideValues,
          alertManagementEnabled: true,
          userCanEnableAlertManagement: true,
          ...provide,
        },
        data() {
          return {
            ...(isErrorAlertDismissed !== undefined ? { isErrorAlertDismissed } : {}),
            ...(searchTerm !== undefined ? { searchTerm } : {}),
            ...(assigneeUsername !== undefined ? { assigneeUsername } : {}),
            ...(sort !== undefined ? { sort } : {}),
          };
        },
        stubs,
        directives: {
          GlTooltip: createMockDirective('gl-tooltip'),
        },
      }),
    );

    if (!loading) {
      await waitForPromises();
    }
  }

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('Alerts table', () => {
    it('loading state', () => {
      mountComponent({
        data: { alerts: {}, alertsCount: null },
        loading: true,
      });
      expect(findAlertsTable().exists()).toBe(true);
      expect(findLoader().exists()).toBe(true);
      expect(findAlert().exists()).toBe(false);
    });

    it('error state', async () => {
      await mountComponent({
        data: { alerts: { errors: ['error'] }, alertsCount: null, errored: true },
        loading: false,
      });
      expect(findAlertsTable().exists()).toBe(true);
      expect(findAlertsTable().text()).toContain('No alerts to display');
      expect(findLoader().exists()).toBe(false);
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().props().variant).toBe('danger');
    });

    it('empty state', async () => {
      await mountComponent({
        data: {
          alerts: { list: [], pageInfo: {} },
          alertsCount: { all: 0 },
          errored: false,
          isErrorAlertDismissed: false,
          searchTerm: '',
          assigneeUsername: '',
        },
        loading: false,
      });

      expect(findAlertsTable().exists()).toBe(true);
      expect(findAlertsTable().text()).toContain('No alerts to display');
      expect(findLoader().exists()).toBe(false);
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().props().variant).toBe('info');
    });

    it('has data state', async () => {
      await mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });
      expect(findLoader().exists()).toBe(false);
      expect(findAlertsTable().exists()).toBe(true);
      expect(findAlerts()).toHaveLength(mockAlerts.length);
      for (let i = 0; i < mockAlerts.length; i += 1) {
        expect(findAlerts().at(i).props().variant).toBe(null);
      }
    });

    it('displays the alert ID and title as a link', async () => {
      await mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });

      expect(findFirstIDField().exists()).toBe(true);
      expect(findFirstIDField().text()).toBe(`#${mockAlerts[0].iid} ${mockAlerts[0].title}`);
      expect(findFirstIDLink().text()).toBe(`#${mockAlerts[0].iid} ${mockAlerts[0].title}`);
      expect(findFirstIDLink().attributes('href')).toBe('/1527542/details');
    });

    it('displays status dropdown', async () => {
      await mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });
      expect(findStatusDropdown().exists()).toBe(true);
    });

    it('does not display a dropdown status header', async () => {
      await mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });
      expect(findStatusDropdown().find('.dropdown-title').exists()).toBe(false);
    });

    it('shows correct severity icons', async () => {
      await mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });

      await nextTick();

      expect(wrapper.findComponent(GlTable).exists()).toBe(true);
      expect(findAlertsTable().find('[data-testid="severity-critical-icon"]').exists()).toBe(true);
    });

    it('renders severity text', async () => {
      await mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });

      expect(findSeverityFields().at(0).text()).toBe('Critical');
    });

    it('renders Unassigned when no assignees present', async () => {
      await mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });

      expect(findAssignees().at(0).text()).toBe('Unassigned');
    });

    it('renders user avatar when assignee present', async () => {
      await mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });

      const avatar = findAssignees().at(1).findComponent(GlAvatar);
      const { name, avatarUrl } = mockAlerts[1].assignees.nodes[0];

      expect(avatar.exists()).toBe(true);
      expect(avatar.attributes('label')).toBe(name);
      expect(avatar.props('src')).toBe(avatarUrl);
    });

    it('navigates to the detail page when alert row is clicked', async () => {
      await mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });

      expect(visitUrl).not.toHaveBeenCalled();

      findAlerts().at(0).trigger('click');
      expect(visitUrl).toHaveBeenCalledWith('/1527542/details', false);
    });

    it('navigates to the detail page in new tab when alert row is clicked with the metaKey', async () => {
      await mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });

      expect(visitUrl).not.toHaveBeenCalled();

      findAlerts().at(0).trigger('click', {
        metaKey: true,
      });

      expect(visitUrl).toHaveBeenCalledWith('/1527542/details', true);
    });

    describe('alert issue links', () => {
      beforeEach(async () => {
        await mountComponent({
          data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
          loading: false,
        });
      });

      it('shows "None" when no link exists', () => {
        expect(findIssueFields().at(0).text()).toBe('None');
      });

      it('renders a link when one exists with the issue state and title tooltip', () => {
        const issueField = findIssueFields().at(1);
        const tooltip = getBinding(issueField.element, 'gl-tooltip');

        expect(issueField.text()).toBe(`#1 (closed)`);
        expect(issueField.attributes('href')).toBe('/gitlab-org/gitlab/-/issues/incident/1');
        expect(issueField.attributes('title')).toBe('My test issue');
        expect(tooltip).not.toBe(undefined);
      });
    });

    describe('handle date fields', () => {
      it('should display time ago dates when values provided', async () => {
        await mountComponent({
          data: {
            alerts: {
              list: [
                {
                  iid: '1',
                  title: 'SyntaxError: Invalid or unexpected token',
                  status: 'acknowledged',
                  startedAt: '2020-03-17T23:18:14.996Z',
                  severity: 'high',
                  assignees: { nodes: [] },
                },
              ],
            },
            alertsCount,
            errored: false,
          },
          loading: false,
        });
        expect(findDateFields()).toHaveLength(1);
      });

      it('should not display time ago dates when values not provided', async () => {
        await mountComponent({
          data: {
            alerts: {
              list: [
                {
                  iid: '1',
                  status: 'acknowledged',
                  startedAt: null,
                  severity: 'high',
                  assignees: { nodes: [] },
                },
              ],
            },
            alertsCount,
            errored: false,
          },
          loading: false,
        });
        expect(findDateFields().exists()).toBe(false);
      });

      describe('New Alert indicator', () => {
        const oldAlert = mockAlerts[0];

        const newAlert = { ...oldAlert, isNew: true };

        it('should highlight the row when alert is new', async () => {
          await mountComponent({
            data: { alerts: { list: [newAlert] }, alertsCount, errored: false },
            loading: false,
          });

          expect(findAlerts().at(0).classes()).toContain('new-alert');
        });

        it('should not highlight the row when alert is not new', async () => {
          await mountComponent({
            data: { alerts: { list: [oldAlert] }, alertsCount, errored: false },
            loading: false,
          });

          expect(findAlerts().at(0).classes()).not.toContain('new-alert');
        });
      });
    });
  });

  describe('sorting the alert list by column', () => {
    beforeEach(async () => {
      await mountComponent({
        data: {
          alerts: { list: mockAlerts },
          errored: false,
          sort: 'STARTED_AT_DESC',
          alertsCount,
        },
        loading: false,
        stubs: { GlTable },
      });
    });

    it('updates sort with new direction and column key', () => {
      findSeverityColumnHeader().trigger('click');

      expect(wrapper.vm.$data.sort).toBe('SEVERITY_DESC');

      findSeverityColumnHeader().trigger('click');

      expect(wrapper.vm.$data.sort).toBe('SEVERITY_ASC');
    });
  });

  describe('Search', () => {
    beforeEach(async () => {
      await mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });
    });

    it('renders the search component', () => {
      expect(findSearch().exists()).toBe(true);
    });
  });
});
