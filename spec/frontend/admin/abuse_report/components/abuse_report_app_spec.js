import { GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AbuseReportApp from '~/admin/abuse_report/components/abuse_report_app.vue';
import ReportHeader from '~/admin/abuse_report/components/report_header.vue';
import UserDetails from '~/admin/abuse_report/components/user_details.vue';
import ReportDetails from '~/admin/abuse_report/components/report_details.vue';
import ReportedContent from '~/admin/abuse_report/components/reported_content.vue';
import ActivityEventsList from '~/admin/abuse_report/components/activity_events_list.vue';
import ActivityHistoryItem from '~/admin/abuse_report/components/activity_history_item.vue';
import AbuseReportNotes from '~/admin/abuse_report/components/abuse_report_notes.vue';

import { SUCCESS_ALERT } from '~/admin/abuse_report/constants';
import { mockAbuseReport } from '../mock_data';

describe('AbuseReportApp', () => {
  let wrapper;
  const mockAbuseReportId = mockAbuseReport.report.globalId;
  const { similarOpenReports } = mockAbuseReport.user;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findReportHeader = () => wrapper.findComponent(ReportHeader);
  const findUserDetails = () => wrapper.findComponent(UserDetails);

  const findReportedContent = () => wrapper.findByTestId('reported-content');
  const findReportedContentForSimilarReports = () =>
    wrapper.findAllByTestId('reported-content-similar-open-reports');
  const firstReportedContentForSimilarReports = () =>
    findReportedContentForSimilarReports().at(0).findComponent(ReportedContent);

  const findActivityList = () => wrapper.findComponent(ActivityEventsList);
  const findActivityItem = () => wrapper.findByTestId('activity');

  const findActivityForSimilarReports = () =>
    wrapper.findAllByTestId('activity-similar-open-reports');
  const firstActivityForSimilarReports = () =>
    findActivityForSimilarReports().at(0).findComponent(ActivityHistoryItem);

  const findReportDetails = () => wrapper.findComponent(ReportDetails);

  const findAbuseReportNotes = () => wrapper.findComponent(AbuseReportNotes);

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

  describe('Report header', () => {
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

  describe('User Details', () => {
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

  describe('Reported Content', () => {
    it('renders ReportedContent', () => {
      expect(findReportedContent().props('report')).toBe(mockAbuseReport.report);
    });

    it('renders similar abuse reports', () => {
      expect(findReportedContentForSimilarReports()).toHaveLength(similarOpenReports.length);
      expect(firstReportedContentForSimilarReports().props('report')).toBe(similarOpenReports[0]);
    });
  });

  describe('ReportDetails', () => {
    describe('when abuseReportLabels feature flag is enabled', () => {
      it('renders ReportDetails', () => {
        createComponent({}, { glFeatures: { abuseReportLabels: true } });

        expect(findReportDetails().props('reportId')).toBe(mockAbuseReportId);
      });
    });

    describe('when abuseReportLabels feature flag is disabled', () => {
      it('does not render ReportDetails', () => {
        createComponent({}, { glFeatures: { abuseReportLabels: false } });

        expect(findReportDetails().exists()).toBe(false);
      });
    });
  });

  describe('Activity', () => {
    it('renders the activity events list', () => {
      expect(findActivityList().exists()).toBe(true);
    });

    it('renders activity item for abuse report', () => {
      expect(findActivityItem().props('report')).toBe(mockAbuseReport.report);
    });

    it('renders activity items for similar abuse reports', () => {
      expect(findActivityForSimilarReports()).toHaveLength(similarOpenReports.length);
      expect(firstActivityForSimilarReports().props('report')).toBe(similarOpenReports[0]);
    });
  });

  describe('Notes', () => {
    describe('when abuseReportNotes feature flag is enabled', () => {
      it('renders abuse report notes', () => {
        createComponent({}, { glFeatures: { abuseReportNotes: true } });

        expect(findAbuseReportNotes().exists()).toBe(true);
        expect(findAbuseReportNotes().props()).toMatchObject({
          abuseReportId: mockAbuseReportId,
        });
      });
    });

    describe('when abuseReportNotes feature flag is disabled', () => {
      it('does not render ReportDetails', () => {
        createComponent({}, { glFeatures: { abuseReportNotes: false } });

        expect(findAbuseReportNotes().exists()).toBe(false);
      });
    });
  });
});
