import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import { joinPaths } from '~/lib/utils/url_utility';
import Tracking from '~/tracking';
import AlertDetails from '~/vue_shared/alert_details/components/alert_details.vue';
import AlertSummaryRow from '~/vue_shared/alert_details/components/alert_summary_row.vue';
import { PAGE_CONFIG, SEVERITY_LEVELS } from '~/vue_shared/alert_details/constants';
import createIssueMutation from '~/vue_shared/alert_details/graphql/mutations/alert_issue_create.mutation.graphql';
import alertQuery from '~/vue_shared/alert_details/graphql/queries/alert_sidebar_details.query.graphql';
import AlertDetailsTable from '~/vue_shared/components/alert_details_table.vue';
import DetailLayout from '~/vue_shared/components/detail_layout.vue';
import { useMetricImages } from '~/vue_shared/components/metric_images/store';
import MetricImagesTab from '~/vue_shared/components/metric_images/metric_images_tab.vue';
import mockAlerts from './mocks/alerts.json';

const mockAlert = mockAlerts[0];
const environmentName = 'Production';
const environmentPath = '/fake/path';

Vue.use(PiniaVuePlugin);

jest.mock('~/vue_shared/alert_details/service');

describe('AlertDetails', () => {
  let environmentData = { name: environmentName, path: environmentPath };
  let mock;
  let wrapper;
  let requestHandlers;
  const projectPath = 'root/alerts';
  const projectIssuesPath = 'root/alerts/-/issues';
  const projectId = '1';
  const $router = { push: jest.fn() };

  const defaultHandlers = {
    createIssueMutationMock: jest.fn().mockResolvedValue({
      data: {
        createAlertIssue: {
          errors: [],
          issue: {
            id: 'id',
            iid: 'iid',
            webUrl: 'webUrl',
          },
        },
      },
    }),
    alertQueryMock: jest.fn().mockResolvedValue({
      data: {
        project: {
          id: '1',
          alertManagementAlerts: {
            nodes: [],
          },
        },
      },
    }),
  };

  const createMockApolloProvider = (handlers) => {
    Vue.use(VueApollo);
    requestHandlers = handlers;

    return createMockApollo([
      [alertQuery, handlers.alertQueryMock],
      [createIssueMutation, handlers.createIssueMutationMock],
    ]);
  };

  function createComponent({
    data,
    mountMethod = shallowMount,
    provide = {},
    stubs = {},
    handlers = defaultHandlers,
  } = {}) {
    const pinia = createTestingPinia();
    const metricImagesStore = useMetricImages();
    metricImagesStore.fetchImages.mockResolvedValue();

    wrapper = extendedWrapper(
      mountMethod(AlertDetails, {
        apolloProvider: createMockApolloProvider(handlers),
        provide: {
          alertId: 'alertId',
          projectPath,
          projectIssuesPath,
          projectId,
          ...provide,
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
          $router,
          $route: { params: {} },
        },
        stubs: {
          AlertSummaryRow,
          'metric-images-tab': true,
          DetailLayout: stubComponent(DetailLayout, {
            template: RENDER_ALL_SLOTS_TEMPLATE,
          }),
          ...stubs,
        },
        pinia,
      }),
    );
  }

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  const findTabs = () => wrapper.findByTestId('alert-details-tabs');
  const findCreateIncidentBtn = () => wrapper.findByTestId('create-incident-button');
  const findViewIncidentBtn = () => wrapper.findByTestId('view-incident-button');
  const findIncidentCreationAlert = () => wrapper.findByTestId('incident-creation-error');
  const findEnvironmentName = () => wrapper.findByTestId('environment-name');
  const findEnvironmentPath = () => wrapper.findByTestId('environment-path');
  const findDetailsTable = () => wrapper.findComponent(AlertDetailsTable);
  const findMetricsTab = () => wrapper.findComponent(MetricImagesTab);

  describe('Alert details', () => {
    describe('when alert is null', () => {
      beforeEach(() => {
        createComponent({ data: { alert: null } });
      });

      it('shows an empty state', () => {
        expect(findTabs().exists()).toBe(false);
      });
    });

    describe('when alert is present', () => {
      beforeEach(() => {
        createComponent({ data: { alert: mockAlert } });
      });

      it('renders a tab with overview information', () => {
        expect(wrapper.findByTestId('overview').exists()).toBe(true);
      });

      it('renders a tab with an activity feed', () => {
        expect(wrapper.findByTestId('activity').exists()).toBe(true);
      });

      it('renders severity', () => {
        expect(wrapper.findByTestId('severity').text()).toBe(SEVERITY_LEVELS[mockAlert.severity]);
      });

      it('renders a title', () => {
        createComponent({
          mountMethod: mount,
          data: { alert: { ...mockAlert } },
          stubs: { DetailLayout },
        });
        expect(wrapper.findByTestId('page-heading').text()).toBe(mockAlert.title);
      });

      it('renders a start time', () => {
        expect(wrapper.findByTestId('start-time-item').exists()).toBe(true);
        expect(wrapper.findByTestId('start-time-item').props('time')).toBe(mockAlert.startedAt);
      });
    });

    describe('Metrics tab', () => {
      it('should mount without errors', () => {
        createComponent({
          provide: {
            canUpdate: true,
            iid: '1',
          },
          stubs: {
            MetricImagesTab,
          },
        });

        expect(findMetricsTab().exists()).toBe(true);
      });
    });

    describe('individual alert fields', () => {
      describe.each`
        testId               | field               | data            | isShown
        ${'event-count'}     | ${'eventCount'}     | ${1}            | ${true}
        ${'event-count'}     | ${'eventCount'}     | ${undefined}    | ${false}
        ${'monitoring-tool'} | ${'monitoringTool'} | ${'New Relic'}  | ${true}
        ${'monitoring-tool'} | ${'monitoringTool'} | ${undefined}    | ${false}
        ${'service'}         | ${'service'}        | ${'Prometheus'} | ${true}
        ${'service'}         | ${'service'}        | ${undefined}    | ${false}
        ${'runbook'}         | ${'runbook'}        | ${undefined}    | ${false}
        ${'runbook'}         | ${'runbook'}        | ${'run.com'}    | ${true}
      `(`$desc`, ({ testId, field, data, isShown }) => {
        beforeEach(() => {
          createComponent({ data: { alert: { ...mockAlert, [field]: data } } });
        });

        it(`${field} is ${isShown ? 'displayed' : 'hidden'} correctly`, () => {
          const element = wrapper.findByTestId(testId);
          if (isShown) {
            expect(element.text()).toContain(data.toString());
          } else {
            expect(wrapper.findByTestId(testId).exists()).toBe(false);
          }
        });
      });
    });

    describe('environment fields', () => {
      it('should show the environment name with a link to the path', () => {
        createComponent();
        const path = findEnvironmentPath();

        expect(findEnvironmentName().exists()).toBe(false);
        expect(path.text()).toBe(environmentName);
        expect(path.attributes('href')).toBe(environmentPath);
      });

      it('should only show the environment name if the path is not provided', () => {
        environmentData = { name: environmentName, path: null };
        createComponent();

        expect(findEnvironmentPath().exists()).toBe(false);
        expect(findEnvironmentName().text()).toBe(environmentName);
      });
    });

    describe('Create incident from alert', () => {
      it('should display "View incident" button that links the incident page when incident exists', () => {
        const iid = '3';
        createComponent({
          data: { alert: { ...mockAlert, issue: { iid } }, sidebarStatus: false },
        });

        expect(findViewIncidentBtn().exists()).toBe(true);
        expect(findViewIncidentBtn().attributes('href')).toBe(
          joinPaths(projectIssuesPath, 'incident', iid),
        );
        expect(findCreateIncidentBtn().exists()).toBe(false);
      });

      it('should display "Create incident" button when incident doesn\'t exist yet', async () => {
        const issue = null;
        createComponent({
          data: { alert: { ...mockAlert, issue } },
        });

        await nextTick();
        expect(findViewIncidentBtn().exists()).toBe(false);
        expect(findCreateIncidentBtn().exists()).toBe(true);
      });

      it('calls `$apollo.mutate` with `createIssueQuery`', () => {
        createComponent({
          mountMethod: mount,
          data: { alert: { ...mockAlert } },
        });

        findCreateIncidentBtn().trigger('click');

        expect(requestHandlers.createIssueMutationMock).toHaveBeenCalledWith({
          iid: mockAlert.iid,
          projectPath,
        });
      });

      it('shows error alert when incident creation fails', async () => {
        const errorMsg = 'Something went wrong';
        createComponent({
          mountMethod: mount,
          data: { alert: { ...mockAlert, alertIid: 1 } },
          handlers: {
            ...defaultHandlers,
            createIssueMutationMock: jest.fn().mockRejectedValue(new Error(errorMsg)),
          },
        });

        findCreateIncidentBtn().trigger('click');

        await waitForPromises();
        expect(findIncidentCreationAlert().text()).toBe(`Error: ${errorMsg}`);
      });
    });

    describe('View full alert details', () => {
      beforeEach(async () => {
        createComponent({
          data: { alert: mockAlert },
          handlers: {
            ...defaultHandlers,
            alertQueryMock: jest.fn().mockResolvedValue({
              data: {
                project: {
                  id: '1',
                  alertManagementAlerts: {
                    nodes: [{ id: '1' }],
                  },
                },
              },
            }),
          },
        });
        await waitForPromises();
      });

      it('should display a table of raw alert details data', () => {
        expect(findDetailsTable().exists()).toBe(true);

        expect(findDetailsTable().props()).toStrictEqual({
          alert: mockAlert,
          statuses: PAGE_CONFIG.OPERATIONS.STATUSES,
          loading: false,
        });
      });
    });

    describe('loading state', () => {
      beforeEach(() => {
        createComponent();
      });

      it('passes the loading state to the detail layout', () => {
        expect(wrapper.findComponent(DetailLayout).props('loading')).toBe(true);
      });
    });

    describe('error state', () => {
      it('displays a error state correctly', () => {
        createComponent({ data: { errored: true } });
        expect(wrapper.findComponent(GlAlert).exists()).toBe(true);
      });

      it('renders html-errors correctly', () => {
        createComponent({
          data: { errored: true, sidebarErrorMessage: '<span data-testid="html-error" />' },
        });
        expect(wrapper.findByTestId('html-error').exists()).toBe(true);
      });

      it('does not display an error when dismissed', () => {
        createComponent({ data: { errored: true, isErrorDismissed: true } });
        expect(wrapper.findComponent(GlAlert).exists()).toBe(false);
      });
    });

    describe('header', () => {
      const findPageHeadingDescription = () => wrapper.findByTestId('page-heading-description');
      const stubs = {
        TimeAgoTooltip: { template: '<span>now</span>' },
        DetailLayout,
      };

      describe('individual header fields', () => {
        describe.each`
          createdAt                     | monitoringTool | result
          ${'2020-04-17T23:18:14.996Z'} | ${null}        | ${'Alert Reported now'}
          ${'2020-04-17T23:18:14.996Z'} | ${'Datadog'}   | ${'Alert Reported now by Datadog'}
        `(
          `When createdAt=$createdAt, monitoringTool=$monitoringTool`,
          ({ createdAt, monitoringTool, result }) => {
            beforeEach(() => {
              createComponent({
                data: { alert: { ...mockAlert, createdAt, monitoringTool } },
                mountMethod: mount,
                stubs,
              });
            });

            it('header text is shown correctly', () => {
              expect(findPageHeadingDescription().text()).toBe(result);
            });
          },
        );
      });
    });

    describe('tab navigation', () => {
      beforeEach(() => {
        createComponent({ data: { alert: mockAlert } });
      });

      it.each`
        index | tabId
        ${0}  | ${'overview'}
        ${1}  | ${'metrics'}
        ${2}  | ${'activity'}
      `('will navigate to the correct tab via $tabId', ({ index, tabId }) => {
        findTabs().vm.$emit('input', index);
        expect($router.push).toHaveBeenCalledWith({ name: 'tab', params: { tabId } });
      });
    });
  });

  describe('Snowplow tracking', () => {
    const mountOptions = {
      props: { alertManagementEnabled: true, userCanEnableAlertManagement: true },
      data: { alert: mockAlert },
      loading: false,
    };

    beforeEach(() => {
      jest.spyOn(Tracking, 'event');
    });

    it('should not track alert details page views when the tracking options do not exist', () => {
      createComponent(mountOptions);
      expect(Tracking.event).not.toHaveBeenCalled();
    });

    it('should track alert details page views when the tracking options exist', () => {
      const trackAlertsDetailsViewsOptions = {
        category: 'Alert Management',
        action: 'view_alert_details',
      };
      createComponent({ ...mountOptions, provide: { trackAlertsDetailsViewsOptions } });
      const { category, action } = trackAlertsDetailsViewsOptions;
      expect(Tracking.event).toHaveBeenCalledWith(category, action);
    });
  });
});
