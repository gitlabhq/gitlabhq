import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TracingList from '~/tracing/components/tracing_list.vue';
import TracingEmptyState from '~/tracing/components/tracing_empty_state.vue';
import TracingTableList from '~/tracing/components/tracing_table_list.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';

jest.mock('~/alert');

describe('TracingList', () => {
  let wrapper;
  let observabilityClientMock;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(TracingEmptyState);
  const findTableList = () => wrapper.findComponent(TracingTableList);

  const mountComponent = async () => {
    wrapper = shallowMountExtended(TracingList, {
      propsData: {
        observabilityClient: observabilityClientMock,
        stubs: {
          GlLoadingIcon: true,
          TracingEmptyState: true,
          TracingTableList: true,
        },
      },
    });
    await waitForPromises();
  };

  beforeEach(() => {
    observabilityClientMock = {
      isTracingEnabled: jest.fn(),
      enableTraces: jest.fn(),
      fetchTraces: jest.fn(),
    };
  });

  it('renders the loading indicator while checking if tracing is enabled', () => {
    mountComponent();
    expect(findLoadingIcon().exists()).toBe(true);
    expect(observabilityClientMock.isTracingEnabled).toHaveBeenCalled();
  });

  describe('when tracing is enabled', () => {
    const mockTraces = ['trace1', 'trace2'];
    beforeEach(async () => {
      observabilityClientMock.isTracingEnabled.mockResolvedValueOnce(true);
      observabilityClientMock.fetchTraces.mockResolvedValueOnce(mockTraces);

      await mountComponent();
    });
    it('fetches the traces and renders the trace list', () => {
      expect(observabilityClientMock.isTracingEnabled).toHaveBeenCalled();
      expect(observabilityClientMock.fetchTraces).toHaveBeenCalled();
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(false);
      expect(findTableList().exists()).toBe(true);
      expect(findTableList().props('traces')).toBe(mockTraces);
    });

    it('calls fetchTraces method when TracingTableList emits reload event', () => {
      observabilityClientMock.fetchTraces.mockClear();
      observabilityClientMock.fetchTraces.mockResolvedValueOnce(['trace1']);

      findTableList().vm.$emit('reload');

      expect(observabilityClientMock.fetchTraces).toHaveBeenCalledTimes(1);
    });
  });

  describe('when tracing is not enabled', () => {
    beforeEach(async () => {
      observabilityClientMock.isTracingEnabled.mockResolvedValueOnce(false);
      observabilityClientMock.fetchTraces.mockResolvedValueOnce([]);

      await mountComponent();
    });

    it('renders TracingEmptyState', () => {
      expect(findEmptyState().exists()).toBe(true);
    });

    it('set enableTracing as TracingEmptyState enable-tracing callback', () => {
      findEmptyState().props('enableTracing')();

      expect(observabilityClientMock.enableTraces).toHaveBeenCalled();
    });
  });

  describe('error handling', () => {
    it('if isTracingEnabled fails, it renders an alert and empty page', async () => {
      observabilityClientMock.isTracingEnabled.mockRejectedValueOnce('error');

      await mountComponent();

      expect(createAlert).toHaveBeenCalledWith({ message: 'Failed to load page.' });
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(false);
      expect(findTableList().exists()).toBe(false);
    });

    it('if fetchTraces fails, it renders an alert and empty list', async () => {
      observabilityClientMock.fetchTraces.mockRejectedValueOnce('error');
      observabilityClientMock.isTracingEnabled.mockReturnValueOnce(true);

      await mountComponent();

      expect(createAlert).toHaveBeenCalledWith({ message: 'Failed to load traces.' });
      expect(findTableList().exists()).toBe(true);
      expect(findTableList().props('traces')).toEqual([]);
    });

    it('if enableTraces fails, it renders an alert and empty-state', async () => {
      observabilityClientMock.isTracingEnabled.mockReturnValueOnce(false);
      observabilityClientMock.enableTraces.mockRejectedValueOnce('error');

      await mountComponent();

      findEmptyState().props('enableTracing')();
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({ message: 'Failed to enable tracing.' });
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(true);
      expect(findTableList().exists()).toBe(false);
    });
  });
});
