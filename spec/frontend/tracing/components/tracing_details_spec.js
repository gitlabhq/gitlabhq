import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TracingDetails from '~/tracing/components/tracing_details.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { visitUrl, isSafeURL } from '~/lib/utils/url_utility';
import TracingDetailsChart from '~/tracing/components/tracing_details_chart.vue';
import TracingDetailsHeader from '~/tracing/components/tracing_details_header.vue';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility');

describe('TracingDetails', () => {
  let wrapper;
  let observabilityClientMock;

  const TRACE_ID = 'test-trace-id';
  const TRACING_INDEX_URL = 'https://www.gitlab.com/flightjs/Flight/-/tracing';

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findTraceDetails = () => wrapper.findComponentByTestId('trace-details');

  const props = {
    traceId: TRACE_ID,
    tracingIndexUrl: TRACING_INDEX_URL,
  };

  const mountComponent = async () => {
    wrapper = shallowMountExtended(TracingDetails, {
      propsData: {
        ...props,
        observabilityClient: observabilityClientMock,
      },
    });
    await waitForPromises();
  };

  beforeEach(() => {
    isSafeURL.mockReturnValue(true);

    observabilityClientMock = {
      isTracingEnabled: jest.fn(),
      fetchTrace: jest.fn(),
    };
  });

  it('renders the loading indicator while checking if tracing is enabled', () => {
    mountComponent();

    expect(findLoadingIcon().exists()).toBe(true);
    expect(observabilityClientMock.isTracingEnabled).toHaveBeenCalled();
  });

  describe('when tracing is enabled', () => {
    const mockTrace = { traceId: 'test-trace-id', foo: 'bar' };
    beforeEach(async () => {
      observabilityClientMock.isTracingEnabled.mockResolvedValueOnce(true);
      observabilityClientMock.fetchTrace.mockResolvedValueOnce(mockTrace);

      await mountComponent();
    });

    it('fetches the trace and renders the trace details', () => {
      expect(observabilityClientMock.isTracingEnabled).toHaveBeenCalled();
      expect(observabilityClientMock.fetchTrace).toHaveBeenCalled();
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findTraceDetails().exists()).toBe(true);
    });

    it('renders the correct components', () => {
      const details = findTraceDetails();
      expect(details.findComponent(TracingDetailsChart).exists()).toBe(true);
      expect(details.findComponent(TracingDetailsHeader).exists()).toBe(true);
    });
  });

  describe('when tracing is not enabled', () => {
    beforeEach(async () => {
      observabilityClientMock.isTracingEnabled.mockResolvedValueOnce(false);

      await mountComponent();
    });

    it('redirects to tracingIndexUrl', () => {
      expect(visitUrl).toHaveBeenCalledWith(props.tracingIndexUrl);
    });
  });

  describe('error handling', () => {
    it('if isTracingEnabled fails, it renders an alert and empty page', async () => {
      observabilityClientMock.isTracingEnabled.mockRejectedValueOnce('error');

      await mountComponent();

      expect(createAlert).toHaveBeenCalledWith({ message: 'Failed to load trace details.' });
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findTraceDetails().exists()).toBe(false);
    });

    it('if fetchTrace fails, it renders an alert and empty page', async () => {
      observabilityClientMock.isTracingEnabled.mockReturnValueOnce(true);
      observabilityClientMock.fetchTrace.mockRejectedValueOnce('error');

      await mountComponent();

      expect(createAlert).toHaveBeenCalledWith({ message: 'Failed to load trace details.' });
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findTraceDetails().exists()).toBe(false);
    });
  });
});
