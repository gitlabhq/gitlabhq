import {
  GlTable,
  GlAlert,
  GlLoadingIcon,
  GlDisclosureDropdown,
  GlAvatar,
  GlLink,
} from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import mockAlerts from 'jest/vue_shared/alert_details/mocks/alerts.json';
import AlertManagementTable from '~/alert_management/components/alert_management_table.vue';
import { visitUrl } from '~/lib/utils/url_utility';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import defaultProvideValues from '../mocks/alerts_provide_config.json';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrlMock'),
  joinPaths: jest.requireActual('~/lib/utils/url_utility').joinPaths,
  setUrlFragment: jest.requireActual('~/lib/utils/url_utility').setUrlFragment,
}));

describe('AlertManagementTable', () => {
  let wrapper;
  let mock;

  const findAlertsTable = () => wrapper.findComponent(GlTable);
  const findAlerts = () => wrapper.findAll('table tbody tr');
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

  function mountComponent({ provide = {}, data = {}, loading = false, stubs = {} } = {}) {
    wrapper = extendedWrapper(
      mount(AlertManagementTable, {
        provide: {
          ...defaultProvideValues,
          alertManagementEnabled: true,
          userCanEnableAlertManagement: true,
          ...provide,
        },
        data() {
          return data;
        },
        mocks: {
          $apollo: {
            mutate: jest.fn(),
            query: jest.fn(),
            queries: {
              alerts: {
                loading,
              },
            },
          },
        },
        stubs,
        directives: {
          GlTooltip: createMockDirective('gl-tooltip'),
        },
      }),
    );
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

    it('error state', () => {
      mountComponent({
        data: { alerts: { errors: ['error'] }, alertsCount: null, errored: true },
        loading: false,
      });
      expect(findAlertsTable().exists()).toBe(true);
      expect(findAlertsTable().text()).toContain('No alerts to display');
      expect(findLoader().exists()).toBe(false);
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().props().variant).toBe('danger');
    });

    it('empty state', () => {
      mountComponent({
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

    it('has data state', () => {
      mountComponent({
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

    it('displays the alert ID and title as a link', () => {
      mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });

      expect(findFirstIDField().exists()).toBe(true);
      expect(findFirstIDField().text()).toBe(`#${mockAlerts[0].iid} ${mockAlerts[0].title}`);
      expect(findFirstIDLink().text()).toBe(`#${mockAlerts[0].iid} ${mockAlerts[0].title}`);
      expect(findFirstIDLink().attributes('href')).toBe('/1527542/details');
    });

    it('displays status dropdown', () => {
      mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });
      expect(findStatusDropdown().exists()).toBe(true);
    });

    it('does not display a dropdown status header', () => {
      mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });
      expect(findStatusDropdown().find('.dropdown-title').exists()).toBe(false);
    });

    it('shows correct severity icons', async () => {
      mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });

      await nextTick();

      expect(wrapper.findComponent(GlTable).exists()).toBe(true);
      expect(findAlertsTable().find('[data-testid="severity-critical-icon"]').exists()).toBe(true);
    });

    it('renders severity text', () => {
      mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });

      expect(findSeverityFields().at(0).text()).toBe('Critical');
    });

    it('renders Unassigned when no assignees present', () => {
      mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });

      expect(findAssignees().at(0).text()).toBe('Unassigned');
    });

    it('renders user avatar when assignee present', () => {
      mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });

      const avatar = findAssignees().at(1).findComponent(GlAvatar);
      const { src, label } = avatar.attributes();
      const { name, avatarUrl } = mockAlerts[1].assignees.nodes[0];

      expect(avatar.exists()).toBe(true);
      expect(label).toBe(name);
      expect(src).toBe(avatarUrl);
    });

    it('navigates to the detail page when alert row is clicked', () => {
      mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });

      expect(visitUrl).not.toHaveBeenCalled();

      findAlerts().at(0).trigger('click');
      expect(visitUrl).toHaveBeenCalledWith('/1527542/details', false);
    });

    it('navigates to the detail page in new tab when alert row is clicked with the metaKey', () => {
      mountComponent({
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
      beforeEach(() => {
        mountComponent({
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
      it('should display time ago dates when values provided', () => {
        mountComponent({
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
        expect(findDateFields().length).toBe(1);
      });

      it('should not display time ago dates when values not provided', () => {
        mountComponent({
          data: {
            alerts: [
              {
                iid: 1,
                status: 'acknowledged',
                startedAt: null,
                severity: 'high',
              },
            ],
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

        it('should highlight the row when alert is new', () => {
          mountComponent({
            data: { alerts: { list: [newAlert] }, alertsCount, errored: false },
            loading: false,
          });

          expect(findAlerts().at(0).classes()).toContain('new-alert');
        });

        it('should not highlight the row when alert is not new', () => {
          mountComponent({
            data: { alerts: { list: [oldAlert] }, alertsCount, errored: false },
            loading: false,
          });

          expect(findAlerts().at(0).classes()).not.toContain('new-alert');
        });
      });
    });
  });

  describe('sorting the alert list by column', () => {
    beforeEach(() => {
      mountComponent({
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
    beforeEach(() => {
      mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });
    });

    it('renders the search component', () => {
      expect(findSearch().exists()).toBe(true);
    });
  });
});
