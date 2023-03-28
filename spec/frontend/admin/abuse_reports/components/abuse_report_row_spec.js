import { GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AbuseReportRow from '~/admin/abuse_reports/components/abuse_report_row.vue';
import AbuseReportActions from '~/admin/abuse_reports/components/abuse_report_actions.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import { getTimeago } from '~/lib/utils/datetime_utility';
import { mockAbuseReports } from '../mock_data';

describe('AbuseReportRow', () => {
  let wrapper;
  const mockAbuseReport = mockAbuseReports[0];

  const findLinks = () => wrapper.findAllComponents(GlLink);
  const findAbuseReportActions = () => wrapper.findComponent(AbuseReportActions);
  const findListItem = () => wrapper.findComponent(ListItem);
  const findTitle = () => wrapper.findByTestId('title');
  const findUpdatedAt = () => wrapper.findByTestId('updated-at');

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

  it('displays correctly formatted updated at', () => {
    expect(findUpdatedAt().text()).toMatchInterpolatedText(
      `Updated ${getTimeago().format(mockAbuseReport.updatedAt)}`,
    );
  });

  it('renders AbuseReportRowActions with the correct props', () => {
    const actions = findAbuseReportActions();

    expect(actions.exists()).toBe(true);
    expect(actions.props('report')).toMatchObject(mockAbuseReport);
  });
});
