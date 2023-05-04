import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import {
  queryToObject,
  redirectTo,
  removeParams,
  mergeUrlParams,
  updateHistory,
} from '~/lib/utils/url_utility';

import Dashboard from '~/monitoring/components/dashboard.vue';
import DashboardHeader from '~/monitoring/components/dashboard_header.vue';
import { createStore } from '~/monitoring/stores';
import { defaultTimeRange } from '~/vue_shared/constants';
import { dashboardProps } from '../fixture_data';
import { mockProjectDir } from '../mock_data';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility');

describe('dashboard invalid url parameters', () => {
  let store;
  let wrapper;
  let mock;

  const createMountedWrapper = (props = { hasMetrics: true }, options = {}) => {
    wrapper = mount(Dashboard, {
      propsData: { ...dashboardProps, ...props },
      store,
      stubs: { 'graph-group': true, 'dashboard-panel': true, 'dashboard-header': DashboardHeader },
      ...options,
    });
  };

  const findDateTimePicker = () =>
    wrapper.findComponent(DashboardHeader).findComponent({ ref: 'dateTimePicker' });

  beforeEach(() => {
    store = createStore();
    jest.spyOn(store, 'dispatch');

    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    queryToObject.mockReset();
  });

  it('passes default url parameters to the time range picker', async () => {
    queryToObject.mockReturnValue({});

    createMountedWrapper();

    await nextTick();
    expect(findDateTimePicker().props('value')).toEqual(defaultTimeRange);

    expect(store.dispatch).toHaveBeenCalledWith(
      'monitoringDashboard/setTimeRange',
      expect.any(Object),
    );
    expect(store.dispatch).toHaveBeenCalledWith('monitoringDashboard/fetchData', undefined);
  });

  it('passes a fixed time range in the URL to the time range picker', async () => {
    const params = {
      start: '2019-01-01T00:00:00.000Z',
      end: '2019-01-10T00:00:00.000Z',
    };

    queryToObject.mockReturnValue(params);

    createMountedWrapper();

    await nextTick();
    expect(findDateTimePicker().props('value')).toEqual(params);

    expect(store.dispatch).toHaveBeenCalledWith('monitoringDashboard/setTimeRange', params);
    expect(store.dispatch).toHaveBeenCalledWith('monitoringDashboard/fetchData', undefined);
  });

  it('passes a rolling time range in the URL to the time range picker', async () => {
    queryToObject.mockReturnValue({
      duration_seconds: '120',
    });

    createMountedWrapper();

    await nextTick();
    const expectedTimeRange = {
      duration: { seconds: 60 * 2 },
    };

    expect(findDateTimePicker().props('value')).toMatchObject(expectedTimeRange);

    expect(store.dispatch).toHaveBeenCalledWith(
      'monitoringDashboard/setTimeRange',
      expectedTimeRange,
    );
    expect(store.dispatch).toHaveBeenCalledWith('monitoringDashboard/fetchData', undefined);
  });

  it('shows an error message and loads a default time range if invalid url parameters are passed', async () => {
    queryToObject.mockReturnValue({
      start: '<script>alert("XSS")</script>',
      end: '<script>alert("XSS")</script>',
    });

    createMountedWrapper();

    await nextTick();
    expect(createAlert).toHaveBeenCalled();

    expect(findDateTimePicker().props('value')).toEqual(defaultTimeRange);

    expect(store.dispatch).toHaveBeenCalledWith(
      'monitoringDashboard/setTimeRange',
      defaultTimeRange,
    );
    expect(store.dispatch).toHaveBeenCalledWith('monitoringDashboard/fetchData', undefined);
  });

  it('redirects to different time range', async () => {
    const toUrl = `${mockProjectDir}/-/metrics?environment=1`;
    removeParams.mockReturnValueOnce(toUrl);

    createMountedWrapper();

    await nextTick();
    findDateTimePicker().vm.$emit('input', {
      duration: { seconds: 120 },
    });

    // redirect to with new parameters
    expect(mergeUrlParams).toHaveBeenCalledWith({ duration_seconds: '120' }, toUrl);
    expect(redirectTo).toHaveBeenCalledTimes(1);
  });

  it('changes the url when a panel moves the time slider', async () => {
    const timeRange = {
      start: '2020-01-01T00:00:00.000Z',
      end: '2020-01-01T01:00:00.000Z',
    };

    queryToObject.mockReturnValue(timeRange);

    createMountedWrapper();

    await nextTick();
    wrapper.vm.onTimeRangeZoom(timeRange);

    expect(updateHistory).toHaveBeenCalled();
    expect(wrapper.vm.selectedTimeRange.start.toString()).toBe(timeRange.start);
    expect(wrapper.vm.selectedTimeRange.end.toString()).toBe(timeRange.end);
  });
});
