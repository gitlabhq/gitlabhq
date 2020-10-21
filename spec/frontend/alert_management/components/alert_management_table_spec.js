import { mount } from '@vue/test-utils';
import { GlTable, GlAlert, GlLoadingIcon, GlDropdown, GlIcon, GlAvatar } from '@gitlab/ui';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { visitUrl } from '~/lib/utils/url_utility';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import AlertManagementTable from '~/alert_management/components/alert_management_table.vue';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import mockAlerts from '../mocks/alerts.json';
import defaultProvideValues from '../mocks/alerts_provide_config.json';

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn().mockName('visitUrlMock'),
  joinPaths: jest.requireActual('~/lib/utils/url_utility').joinPaths,
}));

describe('AlertManagementTable', () => {
  let wrapper;
  let mock;

  const findAlertsTable = () => wrapper.find(GlTable);
  const findAlerts = () => wrapper.findAll('table tbody tr');
  const findAlert = () => wrapper.find(GlAlert);
  const findLoader = () => wrapper.find(GlLoadingIcon);
  const findStatusDropdown = () => wrapper.find(GlDropdown);
  const findDateFields = () => wrapper.findAll(TimeAgo);
  const findSearch = () => wrapper.find(FilteredSearchBar);
  const findSeverityColumnHeader = () =>
    wrapper.find('[data-testid="alert-management-severity-sort"]');
  const findFirstIDField = () => wrapper.findAll('[data-testid="idField"]').at(0);
  const findAssignees = () => wrapper.findAll('[data-testid="assigneesField"]');
  const findSeverityFields = () => wrapper.findAll('[data-testid="severityField"]');
  const findIssueFields = () => wrapper.findAll('[data-testid="issueField"]');
  const alertsCount = {
    open: 24,
    triggered: 20,
    acknowledged: 16,
    resolved: 11,
    all: 26,
  };

  function mountComponent({ provide = {}, data = {}, loading = false, stubs = {} } = {}) {
    wrapper = mount(AlertManagementTable, {
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
    });
  }

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
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
      expect(
        findAlerts()
          .at(0)
          .classes(),
      ).not.toContain('gl-hover-bg-blue-50');
    });

    it('error state', () => {
      mountComponent({
        data: { alerts: { errors: ['error'] }, alertsCount: null, errored: true },
        loading: false,
      });
      expect(findAlertsTable().exists()).toBe(true);
      expect(findAlertsTable().text()).toContain('No alerts to display');
      expect(findLoader().exists()).toBe(false);
      expect(findAlert().props().variant).toBe('danger');
      expect(
        findAlerts()
          .at(0)
          .classes(),
      ).not.toContain('gl-hover-bg-blue-50');
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
      expect(findAlert().props().variant).toBe('info');
      expect(
        findAlerts()
          .at(0)
          .classes(),
      ).not.toContain('gl-hover-bg-blue-50');
    });

    it('has data state', () => {
      mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });
      expect(findLoader().exists()).toBe(false);
      expect(findAlertsTable().exists()).toBe(true);
      expect(findAlerts()).toHaveLength(mockAlerts.length);
      expect(
        findAlerts()
          .at(0)
          .classes(),
      ).toContain('gl-hover-bg-blue-50');
    });

    it('displays the alert ID and title formatted correctly', () => {
      mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });

      expect(findFirstIDField().exists()).toBe(true);
      expect(findFirstIDField().text()).toBe(`#${mockAlerts[0].iid} ${mockAlerts[0].title}`);
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
      expect(
        findStatusDropdown()
          .find('.dropdown-title')
          .exists(),
      ).toBe(false);
    });

    it('shows correct severity icons', async () => {
      mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });

      await wrapper.vm.$nextTick();

      expect(wrapper.find(GlTable).exists()).toBe(true);
      expect(
        findAlertsTable()
          .find(GlIcon)
          .classes('icon-critical'),
      ).toBe(true);
    });

    it('renders severity text', () => {
      mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });

      expect(
        findSeverityFields()
          .at(0)
          .text(),
      ).toBe('Critical');
    });

    it('renders Unassigned when no assignee(s) present', () => {
      mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });

      expect(
        findAssignees()
          .at(0)
          .text(),
      ).toBe('Unassigned');
    });

    it('renders user avatar when assignee present', () => {
      mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });

      const avatar = findAssignees()
        .at(1)
        .find(GlAvatar);
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

      findAlerts()
        .at(0)
        .trigger('click');
      expect(visitUrl).toHaveBeenCalledWith('/1527542/details', false);
    });

    it('navigates to the detail page in new tab when alert row is clicked with the metaKey', () => {
      mountComponent({
        data: { alerts: { list: mockAlerts }, alertsCount, errored: false },
        loading: false,
      });

      expect(visitUrl).not.toHaveBeenCalled();

      findAlerts()
        .at(0)
        .trigger('click', {
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
        expect(
          findIssueFields()
            .at(0)
            .text(),
        ).toBe('None');
      });

      it('renders a link when one exists', () => {
        expect(
          findIssueFields()
            .at(1)
            .text(),
        ).toBe('#1');
        expect(
          findIssueFields()
            .at(1)
            .attributes('href'),
        ).toBe('/gitlab-org/gitlab/-/issues/1');
      });
    });

    describe('handle date fields', () => {
      it('should display time ago dates when values provided', () => {
        mountComponent({
          data: {
            alerts: {
              list: [
                {
                  iid: 1,
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

          expect(
            findAlerts()
              .at(0)
              .classes(),
          ).toContain('new-alert');
        });

        it('should not highlight the row when alert is not new', () => {
          mountComponent({
            data: { alerts: { list: [oldAlert] }, alertsCount, errored: false },
            loading: false,
          });

          expect(
            findAlerts()
              .at(0)
              .classes(),
          ).not.toContain('new-alert');
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
