import MockAdapter from 'axios-mock-adapter';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import TerraformPage from '~/merge_requests/reports/terraform/terraform_page.vue';
import { plans } from 'jest/vue_merge_request_widget/components/terraform/mock_data';

describe('TerraformPage', () => {
  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  let wrapper;
  let mock;

  const endpoint = '/terraform_reports';

  const createComponent = () => {
    wrapper = mountExtended(TerraformPage, {
      propsData: { mr: { terraformReportsPath: endpoint } },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(endpoint).reply(HTTP_STATUS_OK, plans, {});
  });

  afterEach(() => mock.restore());

  it('renders the fetched reports', async () => {
    createComponent();
    await waitForPromises();

    expect(wrapper.findByTestId('summary').text()).toBe(
      '4 Terraform reports were generated in your pipelines',
    );
    expect(wrapper.findByTestId('summary-subtitle').text()).toBe(
      '2 Terraform reports failed to generate',
    );
    expect(wrapper.findAllByTestId('section-item')).toHaveLength(6);
    expect(wrapper.findAllByTestId('item-supporting-text').at(0).text()).toBe(
      'Reported Resource Changes: 10 to add, 20 to change, 30 to delete',
    );
  });

  it('tracks view_merge_request_report on mount', () => {
    createComponent();
    const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

    expect(trackEventSpy).toHaveBeenCalledWith(
      'view_merge_request_report',
      { label: 'terraform' },
      undefined,
    );
  });
});
