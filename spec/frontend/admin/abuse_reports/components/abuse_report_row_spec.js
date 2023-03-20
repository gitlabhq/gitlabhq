import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AbuseReportRow from '~/admin/abuse_reports/components/abuse_report_row.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import { getTimeago } from '~/lib/utils/datetime_utility';
import { mockAbuseReports } from '../mock_data';

describe('AbuseReportRow', () => {
  let wrapper;
  const mockAbuseReport = mockAbuseReports[0];

  const findListItem = () => wrapper.findComponent(ListItem);
  const findTitle = () => wrapper.findByTestId('title');
  const findUpdatedAt = () => wrapper.findByTestId('updated-at');

  const createComponent = () => {
    wrapper = shallowMountExtended(AbuseReportRow, {
      propsData: {
        report: mockAbuseReport,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders a ListItem', () => {
    expect(findListItem().exists()).toBe(true);
  });

  it('displays correctly formatted title', () => {
    const { reporter, reportedUser, category } = mockAbuseReport;
    expect(findTitle().text()).toMatchInterpolatedText(
      `${reportedUser.name} reported for ${category} by ${reporter.name}`,
    );
  });

  it('displays correctly formatted updated at', () => {
    expect(findUpdatedAt().text()).toMatchInterpolatedText(
      `Updated ${getTimeago().format(mockAbuseReport.updatedAt)}`,
    );
  });
});
