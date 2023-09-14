import { GlLabel } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import AbuseReportRow from '~/admin/abuse_reports/components/abuse_report_row.vue';
import AbuseCategory from '~/admin/abuse_reports/components/abuse_category.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import { getTimeago } from '~/lib/utils/datetime_utility';
import { SORT_UPDATED_AT } from '~/admin/abuse_reports/constants';
import { mockAbuseReports } from '../mock_data';

describe('AbuseReportRow', () => {
  let wrapper;
  const mockAbuseReport = mockAbuseReports[0];

  const findListItem = () => wrapper.findComponent(ListItem);
  const findAbuseCategory = () => wrapper.findComponent(AbuseCategory);
  const findLabels = () => wrapper.findAllComponents(GlLabel);
  const findAbuseReportTitle = () => wrapper.findByTestId('abuse-report-title');
  const findDisplayedDate = () => wrapper.findByTestId('abuse-report-date');

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(AbuseReportRow, {
      propsData: {
        report: mockAbuseReport,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders a ListItem', () => {
    expect(findListItem().exists()).toBe(true);
  });

  describe('title', () => {
    const { reporter, reportedUser, category, reportPath } = mockAbuseReport;

    it('displays correctly formatted title', () => {
      expect(findAbuseReportTitle().text()).toMatchInterpolatedText(
        `${reportedUser.name} reported for ${category} by ${reporter.name}`,
      );
    });

    it('links to the details page', () => {
      expect(findAbuseReportTitle().attributes('href')).toEqual(reportPath);
    });

    describe('when the reportedUser is missing', () => {
      beforeEach(() => {
        createComponent({ report: { ...mockAbuseReport, reportedUser: null } });
      });

      it('displays correctly formatted title', () => {
        expect(findAbuseReportTitle().text()).toMatchInterpolatedText(
          `Deleted user reported for ${category} by ${reporter.name}`,
        );
      });
    });

    describe('when the reporter is missing', () => {
      beforeEach(() => {
        createComponent({ report: { ...mockAbuseReport, reporter: null } });
      });

      it('displays correctly formatted title', () => {
        expect(findAbuseReportTitle().text()).toMatchInterpolatedText(
          `${reportedUser.name} reported for ${category} by Deleted user`,
        );
      });
    });
  });

  describe('displayed date', () => {
    it('displays correctly formatted created at', () => {
      expect(findDisplayedDate().text()).toMatchInterpolatedText(
        `Created ${getTimeago().format(mockAbuseReport.createdAt)}`,
      );
    });

    describe('when sorted by updated_at', () => {
      it('displays correctly formatted updated at', () => {
        setWindowLocation(`?sort=${SORT_UPDATED_AT.sortDirection.ascending}`);

        createComponent();

        expect(findDisplayedDate().text()).toMatchInterpolatedText(
          `Updated ${getTimeago().format(mockAbuseReport.updatedAt)}`,
        );
      });
    });
  });

  it('renders abuse category', () => {
    expect(findAbuseCategory().exists()).toBe(true);
  });

  it('renders labels', () => {
    const labels = findLabels();
    expect(labels).toHaveLength(2);

    const { color, title } = mockAbuseReports[0].labels[0];
    expect(labels.at(0).props()).toMatchObject({
      backgroundColor: color,
      title,
      target: `${window.location.href}?${encodeURIComponent('label_name[]')}=${title}`,
    });
  });

  describe('aggregated report', () => {
    const mockAggregatedAbuseReport = mockAbuseReports[1];
    const { reportedUser, category, count } = mockAggregatedAbuseReport;

    beforeEach(() => {
      createComponent({ report: mockAggregatedAbuseReport });
    });

    it('displays title with number of aggregated reports', () => {
      expect(findAbuseReportTitle().text()).toMatchInterpolatedText(
        `${reportedUser.name} reported for ${category} by ${count} users`,
      );
    });
  });
});
