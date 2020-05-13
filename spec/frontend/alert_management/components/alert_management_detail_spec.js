import { mount, shallowMount } from '@vue/test-utils';
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import AlertDetails from '~/alert_management/components/alert_details.vue';

import mockAlerts from '../mocks/alerts.json';

const mockAlert = mockAlerts[0];

describe('AlertDetails', () => {
  let wrapper;
  const newIssuePath = 'root/alerts/-/issues/new';

  function mountComponent({
    data,
    createIssueFromAlertEnabled = false,
    loading = false,
    mountMethod = shallowMount,
    stubs = {},
  } = {}) {
    wrapper = mountMethod(AlertDetails, {
      propsData: {
        alertId: 'alertId',
        projectPath: 'projectPath',
        newIssuePath,
      },
      data() {
        return { alert: { ...mockAlert }, ...data };
      },
      provide: {
        glFeatures: { createIssueFromAlertEnabled },
      },
      mocks: {
        $apollo: {
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

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  const findCreatedIssueBtn = () => wrapper.find('[data-testid="createIssueBtn"]');

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

    it('renders a status dropdown containing three items', () => {
      expect(wrapper.findAll('[data-testid="statusDropdownItem"]').length).toBe(3);
    });

    describe('Create issue from alert', () => {
      describe('createIssueFromAlertEnabled feature flag enabled', () => {
        it('should display a button that links to new issue page', () => {
          mountComponent({ createIssueFromAlertEnabled: true });
          expect(findCreatedIssueBtn().exists()).toBe(true);
          expect(findCreatedIssueBtn().attributes('href')).toBe(newIssuePath);
        });
      });

      describe('createIssueFromAlertEnabled feature flag disabled', () => {
        it('should display a button that links to a new issue page', () => {
          mountComponent({ createIssueFromAlertEnabled: false });
          expect(findCreatedIssueBtn().exists()).toBe(false);
        });
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
          severity    | createdAt                     | monitoringTool | result
          ${'MEDIUM'} | ${'2020-04-17T23:18:14.996Z'} | ${null}        | ${'Medium • Reported now'}
          ${'INFO'}   | ${'2020-04-17T23:18:14.996Z'} | ${'Datadog'}   | ${'Info • Reported now by Datadog'}
        `(
          `When severity=$severity, createdAt=$createdAt, monitoringTool=$monitoringTool`,
          ({ severity, createdAt, monitoringTool, result }) => {
            beforeEach(() => {
              mountComponent({
                data: { alert: { ...mockAlert, severity, createdAt, monitoringTool } },
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
});
