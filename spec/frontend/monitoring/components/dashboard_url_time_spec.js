import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import createFlash from '~/flash';
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

jest.mock('~/flash');
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
      provide: { hasManagedPrometheus: false },
    });
  };

  const findDateTimePicker = () => wrapper.find(DashboardHeader).find({ ref: 'dateTimePicker' });

  beforeEach(() => {
    store = createStore();
    jest.spyOn(store, 'dispatch');

    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
    mock.restore();
    queryToObject.mockReset();
  });

  it('passes default url parameters to the time range picker', () => {
    queryToObject.mockReturnValue({});

    createMountedWrapper();

    return wrapper.vm.$nextTick().then(() => {
      expect(findDateTimePicker().props('value')).toEqual(defaultTimeRange);

      expect(store.dispatch).toHaveBeenCalledWith(
        'monitoringDashboard/setTimeRange',
        expect.any(Object),
      );
      expect(store.dispatch).toHaveBeenCalledWith('monitoringDashboard/fetchData', undefined);
    });
  });

  it('passes a fixed time range in the URL to the time range picker', () => {
    const params = {
      start: '2019-01-01T00:00:00.000Z',
      end: '2019-01-10T00:00:00.000Z',
    };

    queryToObject.mockReturnValue(params);

    createMountedWrapper();

    return wrapper.vm.$nextTick().then(() => {
      expect(findDateTimePicker().props('value')).toEqual(params);

      expect(store.dispatch).toHaveBeenCalledWith('monitoringDashboard/setTimeRange', params);
      expect(store.dispatch).toHaveBeenCalledWith('monitoringDashboard/fetchData', undefined);
    });
  });

  it('passes a rolling time range in the URL to the time range picker', () => {
    queryToObject.mockReturnValue({
      duration_seconds: '120',
    });

    createMountedWrapper();

    return wrapper.vm.$nextTick().then(() => {
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
  });

  it('shows an error message and loads a default time range if invalid url parameters are passed', () => {
    queryToObject.mockReturnValue({
      start: '<script>alert("XSS")</script>',
      end: '<script>alert("XSS")</script>',
    });

    createMountedWrapper();

    return wrapper.vm.$nextTick().then(() => {
      expect(createFlash).toHaveBeenCalled();

      expect(findDateTimePicker().props('value')).toEqual(defaultTimeRange);

      expect(store.dispatch).toHaveBeenCalledWith(
        'monitoringDashboard/setTimeRange',
        defaultTimeRange,
      );
      expect(store.dispatch).toHaveBeenCalledWith('monitoringDashboard/fetchData', undefined);
    });
  });

  it('redirects to different time range', () => {
    const toUrl = `${mockProjectDir}/-/environments/1/metrics`;
    removeParams.mockReturnValueOnce(toUrl);

    createMountedWrapper();

    return wrapper.vm.$nextTick().then(() => {
      findDateTimePicker().vm.$emit('input', {
        duration: { seconds: 120 },
      });

      // redirect to with new parameters
      expect(mergeUrlParams).toHaveBeenCalledWith({ duration_seconds: '120' }, toUrl);
      expect(redirectTo).toHaveBeenCalledTimes(1);
    });
  });

  it('changes the url when a panel moves the time slider', () => {
    const timeRange = {
      start: '2020-01-01T00:00:00.000Z',
      end: '2020-01-01T01:00:00.000Z',
    };

    queryToObject.mockReturnValue(timeRange);

    createMountedWrapper();

    return wrapper.vm.$nextTick().then(() => {
      wrapper.vm.onTimeRangeZoom(timeRange);

      expect(updateHistory).toHaveBeenCalled();
      expect(wrapper.vm.selectedTimeRange.start.toString()).toBe(timeRange.start);
      expect(wrapper.vm.selectedTimeRange.end.toString()).toBe(timeRange.end);
    });
  });
});
