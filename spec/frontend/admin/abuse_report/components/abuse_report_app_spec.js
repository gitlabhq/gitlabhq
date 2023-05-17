import { shallowMount } from '@vue/test-utils';
import AbuseReportApp from '~/admin/abuse_report/components/abuse_report_app.vue';
import ReportHeader from '~/admin/abuse_report/components/report_header.vue';
import UserDetails from '~/admin/abuse_report/components/user_details.vue';
import ReportedContent from '~/admin/abuse_report/components/reported_content.vue';
import HistoryItems from '~/admin/abuse_report/components/history_items.vue';
import { mockAbuseReport } from '../mock_data';

describe('AbuseReportApp', () => {
  let wrapper;

  const findReportHeader = () => wrapper.findComponent(ReportHeader);
  const findUserDetails = () => wrapper.findComponent(UserDetails);
  const findReportedContent = () => wrapper.findComponent(ReportedContent);
  const findHistoryItems = () => wrapper.findComponent(HistoryItems);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(AbuseReportApp, {
      propsData: {
        abuseReport: mockAbuseReport,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('ReportHeader', () => {
    it('renders ReportHeader', () => {
      expect(findReportHeader().props('user')).toBe(mockAbuseReport.user);
      expect(findReportHeader().props('actions')).toBe(mockAbuseReport.actions);
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

  it('renders ReportedContent', () => {
    expect(findReportedContent().props('report')).toBe(mockAbuseReport.report);
    expect(findReportedContent().props('reporter')).toBe(mockAbuseReport.reporter);
  });

  it('renders HistoryItems', () => {
    expect(findHistoryItems().props('report')).toBe(mockAbuseReport.report);
    expect(findHistoryItems().props('reporter')).toBe(mockAbuseReport.reporter);
  });
});
