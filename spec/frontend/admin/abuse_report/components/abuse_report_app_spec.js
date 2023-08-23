import { GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AbuseReportApp from '~/admin/abuse_report/components/abuse_report_app.vue';
import ReportHeader from '~/admin/abuse_report/components/report_header.vue';
import UserDetails from '~/admin/abuse_report/components/user_details.vue';
import ReportDetails from '~/admin/abuse_report/components/report_details.vue';
import ReportedContent from '~/admin/abuse_report/components/reported_content.vue';
import HistoryItems from '~/admin/abuse_report/components/history_items.vue';
import { SUCCESS_ALERT } from '~/admin/abuse_report/constants';
import { mockAbuseReport } from '../mock_data';

describe('AbuseReportApp', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findReportHeader = () => wrapper.findComponent(ReportHeader);
  const findUserDetails = () => wrapper.findComponent(UserDetails);
  const findReportedContent = () => wrapper.findByTestId('reported-content');
  const findSimilarOpenReports = () => wrapper.findAllByTestId('similar-open-reports');
  const findSimilarReportedContent = () =>
    findSimilarOpenReports().at(0).findComponent(ReportedContent);
  const findHistoryItems = () => wrapper.findComponent(HistoryItems);
  const findReportDetails = () => wrapper.findComponent(ReportDetails);

  const createComponent = (props = {}, provide = {}) => {
    wrapper = shallowMountExtended(AbuseReportApp, {
      propsData: {
        abuseReport: mockAbuseReport,
        ...props,
      },
      provide,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('does not show the alert by default', () => {
    expect(findAlert().exists()).toBe(false);
  });

  describe('when emitting the showAlert event from the report header', () => {
    const message = 'alert message';

    beforeEach(() => {
      findReportHeader().vm.$emit('showAlert', SUCCESS_ALERT, message);
    });

    it('shows the alert', () => {
      expect(findAlert().exists()).toBe(true);
    });

    it('displays the message', () => {
      expect(findAlert().text()).toBe(message);
    });

    it('sets the variant property', () => {
      expect(findAlert().props('variant')).toBe(SUCCESS_ALERT);
    });

    describe('when dismissing the alert', () => {
      beforeEach(() => {
        findAlert().vm.$emit('dismiss');
      });

      it('hides the alert', () => {
        expect(findAlert().exists()).toBe(false);
      });
    });
  });

  describe('ReportHeader', () => {
    it('renders ReportHeader', () => {
      expect(findReportHeader().props('user')).toBe(mockAbuseReport.user);
      expect(findReportHeader().props('report')).toBe(mockAbuseReport.report);
    });

    describe('when no user is present', () => {
      beforeEach(() => {
        createComponent({
          abuseReport: { ...mockAbuseReport, user: undefined },
        });
      });

      it('does not render the ReportHeader', () => {
        expect(findReportHeader().exists()).toBe(false);
      });
    });
  });

  describe('UserDetails', () => {
    it('renders UserDetails', () => {
      expect(findUserDetails().props('user')).toBe(mockAbuseReport.user);
    });

    describe('when no user is present', () => {
      beforeEach(() => {
        createComponent({
          abuseReport: { ...mockAbuseReport, user: undefined },
        });
      });

      it('does not render the UserDetails', () => {
        expect(findUserDetails().exists()).toBe(false);
      });
    });
  });

  describe('ReportDetails', () => {
    describe('when abuseReportLabels feature flag is enabled', () => {
      it('renders ReportDetails', () => {
        createComponent({}, { glFeatures: { abuseReportLabels: true } });

        expect(findReportDetails().props('reportId')).toBe(mockAbuseReport.report.globalId);
      });
    });

    describe('when abuseReportLabels feature flag is disabled', () => {
      it('does not render ReportDetails', () => {
        createComponent({}, { glFeatures: { abuseReportLabels: false } });

        expect(findReportDetails().exists()).toBe(false);
      });
    });
  });

  it('renders ReportedContent', () => {
    expect(findReportedContent().props('report')).toBe(mockAbuseReport.report);
  });

  it('renders similar abuse reports', () => {
    const { similarOpenReports } = mockAbuseReport.user;

    expect(findSimilarOpenReports()).toHaveLength(similarOpenReports.length);
    expect(findSimilarReportedContent().props('report')).toBe(similarOpenReports[0]);
  });

  it('renders HistoryItems', () => {
    expect(findHistoryItems().props('report')).toBe(mockAbuseReport.report);
  });
});
