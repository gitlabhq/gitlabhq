import { mount, shallowMount } from '@vue/test-utils';
import { GlAlert, GlLoadingIcon, GlTable } from '@gitlab/ui';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import AlertDetails from '~/alert_management/components/alert_details.vue';
import createIssueQuery from '~/alert_management/graphql/mutations/create_issue_from_alert.graphql';
import { joinPaths } from '~/lib/utils/url_utility';
import {
  trackAlertsDetailsViewsOptions,
  ALERTS_SEVERITY_LABELS,
} from '~/alert_management/constants';
import Tracking from '~/tracking';
import mockAlerts from '../mocks/alerts.json';

const mockAlert = mockAlerts[0];

describe('AlertDetails', () => {
  let wrapper;
  let mock;
  const projectPath = 'root/alerts';
  const projectIssuesPath = 'root/alerts/-/issues';

  const findDetailsTable = () => wrapper.find(GlTable);

  function mountComponent({ data, loading = false, mountMethod = shallowMount, stubs = {} } = {}) {
    wrapper = mountMethod(AlertDetails, {
      propsData: {
        alertId: 'alertId',
        projectPath,
        projectIssuesPath,
      },
      data() {
        return { alert: { ...mockAlert }, ...data };
      },
      mocks: {
        $apollo: {
          mutate: jest.fn(),
          queries: {
            alert: {
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
      if (wrapper) {
        wrapper.destroy();
      }
    }
    mock.restore();
  });

  const findCreateIssueBtn = () => wrapper.find('[data-testid="createIssueBtn"]');
  const findViewIssueBtn = () => wrapper.find('[data-testid="viewIssueBtn"]');
  const findIssueCreationAlert = () => wrapper.find('[data-testid="issueCreationError"]');

  describe('Alert details', () => {
    describe('when alert is null', () => {
      beforeEach(() => {
        mountComponent({ data: { alert: null } });
      });

      it('shows an empty state', () => {
        expect(wrapper.find('[data-testid="alertDetailsTabs"]').exists()).toBe(false);
      });
    });

    describe('when alert is present', () => {
      beforeEach(() => {
        mountComponent({ data: { alert: mockAlert } });
      });

      it('renders a tab with overview information', () => {
        expect(wrapper.find('[data-testid="overviewTab"]').exists()).toBe(true);
      });

      it('renders a tab with full alert information', () => {
        expect(wrapper.find('[data-testid="fullDetailsTab"]').exists()).toBe(true);
      });

      it('renders severity', () => {
        expect(wrapper.find('[data-testid="severity"]').text()).toBe(
          ALERTS_SEVERITY_LABELS[mockAlert.severity],
        );
      });

      it('renders a title', () => {
        expect(wrapper.find('[data-testid="title"]').text()).toBe(mockAlert.title);
      });

      it('renders a start time', () => {
        expect(wrapper.find('[data-testid="startTimeItem"]').exists()).toBe(true);
        expect(wrapper.find('[data-testid="startTimeItem"]').props().time).toBe(
          mockAlert.startedAt,
        );
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
      `(`$desc`, ({ field, data, isShown }) => {
        beforeEach(() => {
          mountComponent({ data: { alert: { ...mockAlert, [field]: data } } });
        });

        it(`${field} is ${isShown ? 'displayed' : 'hidden'} correctly`, () => {
          if (isShown) {
            expect(wrapper.find(`[data-testid="${field}"]`).text()).toBe(data.toString());
          } else {
            expect(wrapper.find(`[data-testid="${field}"]`).exists()).toBe(false);
          }
        });
      });
    });

    describe('Create issue from alert', () => {
      it('should display "View issue" button that links the issue page when issue exists', () => {
        const issueIid = '3';
        mountComponent({
          data: { alert: { ...mockAlert, issueIid } },
        });
        expect(findViewIssueBtn().exists()).toBe(true);
        expect(findViewIssueBtn().attributes('href')).toBe(joinPaths(projectIssuesPath, issueIid));
        expect(findCreateIssueBtn().exists()).toBe(false);
      });

      it('should display "Create issue" button when issue doesn\'t exist yet', () => {
        const issueIid = null;
        mountComponent({
          mountMethod: mount,
          data: { alert: { ...mockAlert, issueIid } },
        });
        expect(findViewIssueBtn().exists()).toBe(false);
        expect(findCreateIssueBtn().exists()).toBe(true);
      });

      it('calls `$apollo.mutate` with `createIssueQuery`', () => {
        const issueIid = '10';
        jest
          .spyOn(wrapper.vm.$apollo, 'mutate')
          .mockResolvedValue({ data: { createAlertIssue: { issue: { iid: issueIid } } } });

        findCreateIssueBtn().trigger('click');
        expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
          mutation: createIssueQuery,
          variables: {
            iid: mockAlert.iid,
            projectPath,
          },
        });
      });

      it('shows error alert when issue creation fails ', () => {
        const errorMsg = 'Something went wrong';
        mountComponent({
          mountMethod: mount,
          data: { alert: { ...mockAlert, alertIid: 1 } },
        });

        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue(errorMsg);
        findCreateIssueBtn().trigger('click');

        setImmediate(() => {
          expect(findIssueCreationAlert().text()).toBe(errorMsg);
        });
      });
    });

    describe('View full alert details', () => {
      beforeEach(() => {
        mountComponent({ data: { alert: mockAlert } });
      });
      it('should display a table of raw alert details data', () => {
        wrapper.find('[data-testid="fullDetailsTab"]').trigger('click');
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

      it('does not display an error when dismissed', () => {
        mountComponent({ data: { errored: true, isErrorDismissed: true } });
        expect(wrapper.find(GlAlert).exists()).toBe(false);
      });
    });

    describe('header', () => {
      const findHeader = () => wrapper.find('[data-testid="alert-header"]');
      const stubs = { TimeAgoTooltip: '<span>now</span>' };

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
