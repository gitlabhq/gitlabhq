import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TracingList from '~/tracing/components/tracing_list.vue';
import TracingEmptyState from '~/tracing/components/tracing_empty_state.vue';
import TracingTableList from '~/tracing/components/tracing_table_list.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import * as urlUtility from '~/lib/utils/url_utility';
import {
  queryToFilterObj,
  filterObjToQuery,
  filterObjToFilterToken,
  filterTokensToFilterObj,
} from '~/tracing/filters';
import FilteredSearch from '~/tracing/components/tracing_list_filtered_search.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';
import setWindowLocation from 'helpers/set_window_location_helper';

jest.mock('~/alert');
jest.mock('~/tracing/filters');

describe('TracingList', () => {
  let wrapper;
  let observabilityClientMock;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(TracingEmptyState);
  const findTableList = () => wrapper.findComponent(TracingTableList);
  const findFilteredSearch = () => wrapper.findComponent(FilteredSearch);
  const findUrlSync = () => wrapper.findComponent(UrlSync);

  const mountComponent = async () => {
    wrapper = shallowMountExtended(TracingList, {
      propsData: {
        observabilityClient: observabilityClientMock,
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
    expect(findEmptyState().exists()).toBe(false);
    expect(findTableList().exists()).toBe(false);
    expect(findFilteredSearch().exists()).toBe(false);
    expect(findUrlSync().exists()).toBe(false);
    expect(observabilityClientMock.isTracingEnabled).toHaveBeenCalled();
  });

  describe('when tracing is enabled', () => {
    const mockTraces = ['trace1', 'trace2'];
    beforeEach(async () => {
      observabilityClientMock.isTracingEnabled.mockResolvedValueOnce(true);
      observabilityClientMock.fetchTraces.mockResolvedValueOnce(mockTraces);

      await mountComponent();
    });

    it('fetches the traces and renders the trace list with filtered search', () => {
      expect(observabilityClientMock.isTracingEnabled).toHaveBeenCalled();
      expect(observabilityClientMock.fetchTraces).toHaveBeenCalled();
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(false);
      expect(findTableList().exists()).toBe(true);
      expect(findFilteredSearch().exists()).toBe(true);
      expect(findUrlSync().exists()).toBe(true);
      expect(findTableList().props('traces')).toBe(mockTraces);
    });

    it('calls fetchTraces method when TracingTableList emits reload event', () => {
      observabilityClientMock.fetchTraces.mockClear();
      observabilityClientMock.fetchTraces.mockResolvedValueOnce(['trace1']);

      findTableList().vm.$emit('reload');

      expect(observabilityClientMock.fetchTraces).toHaveBeenCalledTimes(1);
    });

    it('on trace selection it redirects to the details url', () => {
      setWindowLocation('base_path');
      const visitUrlMock = jest.spyOn(urlUtility, 'visitUrl').mockReturnValue({});

      findTableList().vm.$emit('trace-selected', { traceId: 'test-trace-id' });

      expect(visitUrlMock).toHaveBeenCalledTimes(1);
      expect(visitUrlMock).toHaveBeenCalledWith('/base_path/test-trace-id');
    });
  });

  describe('filtered search', () => {
    let mockFilterObj;
    let mockFilterToken;
    let mockQuery;
    let mockUpdatedFilterObj;

    beforeEach(async () => {
      observabilityClientMock.isTracingEnabled.mockResolvedValue(true);
      observabilityClientMock.fetchTraces.mockResolvedValue([]);

      setWindowLocation('?trace-id=foo');

      mockFilterObj = { mock: 'filter-obj' };
      queryToFilterObj.mockReturnValue(mockFilterObj);

      mockFilterToken = ['mock-token'];
      filterObjToFilterToken.mockReturnValue(mockFilterToken);

      mockQuery = { mock: 'query' };
      filterObjToQuery.mockReturnValueOnce(mockQuery);

      mockUpdatedFilterObj = { mock: 'filter-obj-upd' };
      filterTokensToFilterObj.mockReturnValue(mockUpdatedFilterObj);

      await mountComponent();
    });

    it('renders FilteredSeach with initial filters parsed from window.location', () => {
      expect(queryToFilterObj).toHaveBeenCalledWith('?trace-id=foo');
      expect(filterObjToFilterToken).toHaveBeenCalledWith(mockFilterObj);
      expect(findFilteredSearch().props('initialFilters')).toBe(mockFilterToken);
    });

    it('renders UrlSync and sets query prop', () => {
      expect(filterObjToQuery).toHaveBeenCalledWith(mockFilterObj);
      expect(findUrlSync().props('query')).toBe(mockQuery);
    });

    it('process filters on search submit', async () => {
      const mockUpdatedQuery = { mock: 'updated-query' };
      filterObjToQuery.mockReturnValueOnce(mockUpdatedQuery);
      const mockFilters = { mock: 'some-filter' };

      findFilteredSearch().vm.$emit('submit', mockFilters);
      await waitForPromises();

      expect(filterTokensToFilterObj).toHaveBeenCalledWith(mockFilters);
      expect(filterObjToQuery).toHaveBeenCalledWith(mockUpdatedFilterObj);
      expect(findUrlSync().props('query')).toBe(mockUpdatedQuery);
    });

    it('fetches traces with filters', () => {
      expect(observabilityClientMock.fetchTraces).toHaveBeenCalledWith(mockFilterObj);

      findFilteredSearch().vm.$emit('submit', {});

      expect(observabilityClientMock.fetchTraces).toHaveBeenLastCalledWith(mockUpdatedFilterObj);
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

    it('calls enableTracing when TracingEmptyState emits enable-tracing', () => {
      findEmptyState().vm.$emit('enable-tracing');

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

      findEmptyState().vm.$emit('enable-tracing');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({ message: 'Failed to enable tracing.' });
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(true);
      expect(findTableList().exists()).toBe(false);
    });
  });
});
