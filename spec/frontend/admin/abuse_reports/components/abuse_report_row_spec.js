import { GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import AbuseReportDetails from '~/admin/abuse_reports/components/abuse_report_details.vue';
import AbuseReportRow from '~/admin/abuse_reports/components/abuse_report_row.vue';
import AbuseReportActions from '~/admin/abuse_reports/components/abuse_report_actions.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import { getTimeago } from '~/lib/utils/datetime_utility';
import { SORT_UPDATED_AT } from '~/admin/abuse_reports/constants';
import { mockAbuseReports } from '../mock_data';

describe('AbuseReportRow', () => {
  let wrapper;
  const mockAbuseReport = mockAbuseReports[0];

  const findLinks = () => wrapper.findAllComponents(GlLink);
  const findAbuseReportActions = () => wrapper.findComponent(AbuseReportActions);
  const findListItem = () => wrapper.findComponent(ListItem);
  const findTitle = () => wrapper.findByTestId('title');
  const findDisplayedDate = () => wrapper.findByTestId('abuse-report-date');
  const findAbuseReportDetails = () => wrapper.findComponent(AbuseReportDetails);

  const createComponent = () => {
    wrapper = shallowMountExtended(AbuseReportRow, {
      propsData: {
        report: mockAbuseReport,
      },
      stubs: { GlSprintf },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders a ListItem', () => {
    expect(findListItem().exists()).toBe(true);
  });

  it('displays correctly formatted title', () => {
    const { reporter, reportedUser, category, reportedUserPath, reporterPath } = mockAbuseReport;
    expect(findTitle().text()).toMatchInterpolatedText(
      `${reportedUser.name} reported for ${category} by ${reporter.name}`,
    );

    const userLink = findLinks().at(0);
    expect(userLink.text()).toEqual(reportedUser.name);
    expect(userLink.attributes('href')).toEqual(reportedUserPath);

    const reporterLink = findLinks().at(1);
    expect(reporterLink.text()).toEqual(reporter.name);
    expect(reporterLink.attributes('href')).toEqual(reporterPath);
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

  it('renders AbuseReportDetails', () => {
    expect(findAbuseReportDetails().exists()).toBe(true);
    expect(findAbuseReportDetails().props('report')).toEqual(mockAbuseReport);
  });

  it('renders AbuseReportRowActions with the correct props', () => {
    const actions = findAbuseReportActions();

    expect(actions.exists()).toBe(true);
    expect(actions.props('report')).toMatchObject(mockAbuseReport);
  });
});
