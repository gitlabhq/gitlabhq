import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import AlertDetails from '~/alert_management/components/alert_details.vue';
import AlertSummaryRow from '~/alert_management/components/alert_summary_row.vue';
import {
  ALERTS_SEVERITY_LABELS,
  trackAlertsDetailsViewsOptions,
} from '~/alert_management/constants';
import createIssueMutation from '~/alert_management/graphql/mutations/create_issue_from_alert.mutation.graphql';
import { joinPaths } from '~/lib/utils/url_utility';
import Tracking from '~/tracking';
import AlertDetailsTable from '~/vue_shared/components/alert_details_table.vue';
import mockAlerts from '../mocks/alerts.json';

const mockAlert = mockAlerts[0];
const environmentName = 'Production';
const environmentPath = '/fake/path';

describe('AlertDetails', () => {
  let environmentData = { name: environmentName, path: environmentPath };
  let mock;
  let wrapper;
  const projectPath = 'root/alerts';
  const projectIssuesPath = 'root/alerts/-/issues';
  const projectId = '1';
  const $router = { replace: jest.fn() };

  function mountComponent({ data, loading = false, mountMethod = shallowMount, stubs = {} } = {}) {
    wrapper = extendedWrapper(
      mountMethod(AlertDetails, {
        provide: {
          alertId: 'alertId',
          projectPath,
          projectIssuesPath,
          projectId,
        },
        data() {
          return {
            alert: {
              ...mockAlert,
              environment: environmentData,
            },
            sidebarStatus: false,
            ...data,
          };
        },
        mocks: {
          $apollo: {
            mutate: jest.fn(),
            queries: {
              alert: {
                loading,
              },
              sidebarStatus: {},
            },
          },
          $router,
          $route: { params: {} },
        },
        stubs: {
          ...stubs,
          AlertSummaryRow,
        },
      }),
    );
  }

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
    mock.restore();
  });

  const findCreateIncidentBtn = () => wrapper.findByTestId('createIncidentBtn');
  const findViewIncidentBtn = () => wrapper.findByTestId('viewIncidentBtn');
  const findIncidentCreationAlert = () => wrapper.findByTestId('incidentCreationError');
  const findEnvironmentName = () => wrapper.findByTestId('environmentName');
  const findEnvironmentPath = () => wrapper.findByTestId('environmentPath');
  const findDetailsTable = () => wrapper.find(AlertDetailsTable);

  describe('Alert details', () => {
    describe('when alert is null', () => {
      beforeEach(() => {
        mountComponent({ data: { alert: null } });
      });

      it('shows an empty state', () => {
        expect(wrapper.findByTestId('alertDetailsTabs').exists()).toBe(false);
      });
    });

    describe('when alert is present', () => {
      beforeEach(() => {
        mountComponent({ data: { alert: mockAlert } });
      });

      it('renders a tab with overview information', () => {
        expect(wrapper.findByTestId('overview').exists()).toBe(true);
      });

      it('renders a tab with an activity feed', () => {
        expect(wrapper.findByTestId('activity').exists()).toBe(true);
      });

      it('renders severity', () => {
        expect(wrapper.findByTestId('severity').text()).toBe(
          ALERTS_SEVERITY_LABELS[mockAlert.severity],
        );
      });

      it('renders a title', () => {
        expect(wrapper.findByTestId('title').text()).toBe(mockAlert.title);
      });

      it('renders a start time', () => {
        expect(wrapper.findByTestId('startTimeItem').exists()).toBe(true);
        expect(wrapper.findByTestId('startTimeItem').props('time')).toBe(mockAlert.startedAt);
      });
    });

    describe('individual alert fields', () => {
      describe.each`
        field               | data            | isShown
        ${'eventCount'}     | ${1}            | ${true}
        ${'eventCount'}     | ${undefined}    | ${false}
        ${'monitoringTool'} | ${'New Relic'}  | ${true}
        ${'monitoringTool'} | ${undefined}    | ${false}
        ${'service'}        | ${'Prometheus'} | ${true}
        ${'service'}        | ${undefined}    | ${false}
        ${'runbook'}        | ${undefined}    | ${false}
        ${'runbook'}        | ${'run.com'}    | ${true}
      `(`$desc`, ({ field, data, isShown }) => {
        beforeEach(() => {
          mountComponent({ data: { alert: { ...mockAlert, [field]: data } } });
        });

        it(`${field} is ${isShown ? 'displayed' : 'hidden'} correctly`, () => {
          const element = wrapper.findByTestId(field);
          if (isShown) {
            expect(element.text()).toContain(data.toString());
          } else {
            expect(wrapper.findByTestId(field).exists()).toBe(false);
          }
        });
      });
    });

    describe('environment fields', () => {
      it('should show the environment name with a link to the path', () => {
        mountComponent();
        const path = findEnvironmentPath();

        expect(findEnvironmentName().exists()).toBe(false);
        expect(path.text()).toBe(environmentName);
        expect(path.attributes('href')).toBe(environmentPath);
      });

      it('should only show the environment name if the path is not provided', () => {
        environmentData = { name: environmentName, path: null };
        mountComponent();

        expect(findEnvironmentPath().exists()).toBe(false);
        expect(findEnvironmentName().text()).toBe(environmentName);
      });
    });

    describe('Create incident from alert', () => {
      it('should display "View incident" button that links the incident page when incident exists', () => {
        const issueIid = '3';
        mountComponent({
          data: { alert: { ...mockAlert, issueIid }, sidebarStatus: false },
        });

        expect(findViewIncidentBtn().exists()).toBe(true);
        expect(findViewIncidentBtn().attributes('href')).toBe(
          joinPaths(projectIssuesPath, issueIid),
        );
        expect(findCreateIncidentBtn().exists()).toBe(false);
      });

      it('should display "Create incident" button when incident doesn\'t exist yet', () => {
        const issueIid = null;
        mountComponent({
          mountMethod: mount,
          data: { alert: { ...mockAlert, issueIid } },
        });

        return wrapper.vm.$nextTick().then(() => {
          expect(findViewIncidentBtn().exists()).toBe(false);
          expect(findCreateIncidentBtn().exists()).toBe(true);
        });
      });

      it('calls `$apollo.mutate` with `createIssueQuery`', () => {
        const issueIid = '10';
        jest
          .spyOn(wrapper.vm.$apollo, 'mutate')
          .mockResolvedValue({ data: { createAlertIssue: { issue: { iid: issueIid } } } });
        findCreateIncidentBtn().trigger('click');

        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
          mutation: createIssueMutation,
          variables: {
            iid: mockAlert.iid,
            projectPath,
          },
        });
      });

      it('shows error alert when incident creation fails ', () => {
        const errorMsg = 'Something went wrong';
        mountComponent({
          mountMethod: mount,
          data: { alert: { ...mockAlert, alertIid: 1 } },
        });

        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue(errorMsg);
        findCreateIncidentBtn().trigger('click');

        setImmediate(() => {
          expect(findIncidentCreationAlert().text()).toBe(errorMsg);
        });
      });
    });

    describe('View full alert details', () => {
      beforeEach(() => {
        mountComponent({ data: { alert: mockAlert } });
      });

      it('should display a table of raw alert details data', () => {
        expect(findDetailsTable().exists()).toBe(true);
      });
    });

    describe('loading state', () => {
      beforeEach(() => {
        mountComponent({ loading: true });
      });

      it('displays a loading state when loading', () => {
        expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
      });
    });

    describe('error state', () => {
      it('displays a error state correctly', () => {
        mountComponent({ data: { errored: true } });
        expect(wrapper.find(GlAlert).exists()).toBe(true);
      });

      it('renders html-errors correctly', () => {
        mountComponent({
          data: { errored: true, sidebarErrorMessage: '<span data-testid="htmlError" />' },
        });
        expect(wrapper.findByTestId('htmlError').exists()).toBe(true);
      });

      it('does not display an error when dismissed', () => {
        mountComponent({ data: { errored: true, isErrorDismissed: true } });
        expect(wrapper.find(GlAlert).exists()).toBe(false);
      });
    });

    describe('header', () => {
      const findHeader = () => wrapper.findByTestId('alert-header');
      const stubs = { TimeAgoTooltip: { template: '<span>now</span>' } };

      describe('individual header fields', () => {
        describe.each`
          createdAt                     | monitoringTool | result
          ${'2020-04-17T23:18:14.996Z'} | ${null}        | ${'Alert Reported now'}
          ${'2020-04-17T23:18:14.996Z'} | ${'Datadog'}   | ${'Alert Reported now by Datadog'}
        `(
          `When createdAt=$createdAt, monitoringTool=$monitoringTool`,
          ({ createdAt, monitoringTool, result }) => {
            beforeEach(() => {
              mountComponent({
                data: { alert: { ...mockAlert, createdAt, monitoringTool } },
                mountMethod: mount,
                stubs,
              });
            });

            it('header text is shown correctly', () => {
              expect(findHeader().text()).toBe(result);
            });
          },
        );
      });
    });

    describe('tab navigation', () => {
      beforeEach(() => {
        mountComponent({ data: { alert: mockAlert } });
      });

      it.each`
        index | tabId
        ${0}  | ${'overview'}
        ${1}  | ${'metrics'}
        ${2}  | ${'activity'}
      `('will navigate to the correct tab via $tabId', ({ index, tabId }) => {
        wrapper.setData({ currentTabIndex: index });
        expect($router.replace).toHaveBeenCalledWith({ name: 'tab', params: { tabId } });
      });
    });
  });

  describe('Snowplow tracking', () => {
    beforeEach(() => {
      jest.spyOn(Tracking, 'event');
      mountComponent({
        props: { alertManagementEnabled: true, userCanEnableAlertManagement: true },
        data: { alert: mockAlert },
        loading: false,
      });
    });

    it('should track alert details page views', () => {
      const { category, action } = trackAlertsDetailsViewsOptions;
      expect(Tracking.event).toHaveBeenCalledWith(category, action);
    });
  });
});
