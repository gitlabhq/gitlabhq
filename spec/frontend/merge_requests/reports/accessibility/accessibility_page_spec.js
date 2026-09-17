import MockAdapter from 'axios-mock-adapter';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import AccessibilityPage from '~/merge_requests/reports/accessibility/accessibility_page.vue';
import { accessibilityReportResponseErrors } from 'jest/vue_merge_request_widget/widgets/accessibility/mock_data';

describe('AccessibilityPage', () => {
  let wrapper;
  let mock;

  const endpoint = '/accessibility_reports';

  const createComponent = () => {
    wrapper = mountExtended(AccessibilityPage, {
      propsData: { mr: { accessibilityReportPath: endpoint } },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(endpoint).reply(HTTP_STATUS_OK, accessibilityReportResponseErrors, {});
  });

  afterEach(() => mock.restore());

  it('renders the fetched report as grouped sections', async () => {
    createComponent();
    await waitForPromises();

    expect(wrapper.findByTestId('summary').text()).toBe(
      'Accessibility scanning detected 5 issues for the source branch only',
    );
    expect(wrapper.findAllByTestId('section-header').wrappers.map((w) => w.text())).toEqual([
      'New',
      'Not fixed',
      'Fixed',
    ]);
    expect(wrapper.findAllByTestId('section-item')).toHaveLength(7);
  });

  describe('tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    it('tracks view_merge_request_report on mount', () => {
      createComponent();
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      expect(trackEventSpy).toHaveBeenCalledWith(
        'view_merge_request_report',
        { label: 'accessibility' },
        undefined,
      );
    });
  });
});
