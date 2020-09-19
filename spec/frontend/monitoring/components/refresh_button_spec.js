import { shallowMount } from '@vue/test-utils';
import Visibility from 'visibilityjs';
import { GlDropdown, GlDropdownItem, GlButton } from '@gitlab/ui';
import { createStore } from '~/monitoring/stores';
import RefreshButton from '~/monitoring/components/refresh_button.vue';

describe('RefreshButton', () => {
  let wrapper;
  let store;
  let dispatch;
  let documentHidden;

  const createWrapper = (options = {}) => {
    wrapper = shallowMount(RefreshButton, { store, ...options });
  };

  const findRefreshBtn = () => wrapper.find(GlButton);
  const findDropdown = () => wrapper.find(GlDropdown);
  const findOptions = () => findDropdown().findAll(GlDropdownItem);
  const findOptionAt = index => findOptions().at(index);

  const expectFetchDataToHaveBeenCalledTimes = times => {
    const refreshCalls = dispatch.mock.calls.filter(([action, payload]) => {
      return action === 'monitoringDashboard/fetchDashboardData' && payload === undefined;
    });
    expect(refreshCalls).toHaveLength(times);
  };

  beforeEach(() => {
    store = createStore();
    jest.spyOn(store, 'dispatch').mockResolvedValue();
    dispatch = store.dispatch;

    documentHidden = false;
    jest.spyOn(Visibility, 'hidden').mockImplementation(() => documentHidden);

    createWrapper();
  });

  afterEach(() => {
    dispatch.mockReset();
    wrapper.destroy();
  });

  it('refreshes data when "refresh" is clicked', () => {
    findRefreshBtn().vm.$emit('click');
    expectFetchDataToHaveBeenCalledTimes(1);
  });

  it('refresh rate is "Off" in the dropdown', () => {
    expect(findDropdown().props('text')).toBe('Off');
  });

  describe('when feature flag disable_metric_dashboard_refresh_rate is on', () => {
    beforeEach(() => {
      createWrapper({
        provide: {
          glFeatures: { disableMetricDashboardRefreshRate: true },
        },
      });
    });

    it('refresh rate is not available', () => {
      expect(findDropdown().exists()).toBe(false);
    });
  });

  describe('refresh rate options', () => {
    it('presents multiple options', () => {
      expect(findOptions().length).toBeGreaterThan(1);
    });

    it('presents an "Off" option as the default option', () => {
      expect(findOptionAt(0).text()).toBe('Off');
      expect(findOptionAt(0).props('isChecked')).toBe(true);
    });
  });

  describe('when a refresh rate is chosen', () => {
    const optIndex = 2; // Other option than "Off"

    beforeEach(() => {
      findOptionAt(optIndex).vm.$emit('click');
      return wrapper.vm.$nextTick;
    });

    it('refresh rate appears in the dropdown', () => {
      expect(findDropdown().props('text')).toBe('10s');
    });

    it('refresh rate option is checked', () => {
      expect(findOptionAt(0).props('isChecked')).toBe(false);
      expect(findOptionAt(optIndex).props('isChecked')).toBe(true);
    });

    it('refreshes data when a new refresh rate is chosen', () => {
      expectFetchDataToHaveBeenCalledTimes(1);
    });

    it('refreshes data after two intervals of time have passed', async () => {
      jest.runOnlyPendingTimers();
      expectFetchDataToHaveBeenCalledTimes(2);

      await wrapper.vm.$nextTick();

      jest.runOnlyPendingTimers();
      expectFetchDataToHaveBeenCalledTimes(3);
    });

    it('does not refresh data if the document is hidden', async () => {
      documentHidden = true;

      jest.runOnlyPendingTimers();
      expectFetchDataToHaveBeenCalledTimes(1);

      await wrapper.vm.$nextTick();

      jest.runOnlyPendingTimers();
      expectFetchDataToHaveBeenCalledTimes(1);
    });

    it('data is not refreshed anymore after component is destroyed', () => {
      expect(jest.getTimerCount()).toBe(1);

      wrapper.destroy();

      expect(jest.getTimerCount()).toBe(0);
    });

    describe('when "Off" refresh rate is chosen', () => {
      beforeEach(() => {
        findOptionAt(0).vm.$emit('click');
        return wrapper.vm.$nextTick;
      });

      it('refresh rate is "Off" in the dropdown', () => {
        expect(findDropdown().props('text')).toBe('Off');
      });

      it('refresh rate option is appears selected', () => {
        expect(findOptionAt(0).props('isChecked')).toBe(true);
        expect(findOptionAt(optIndex).props('isChecked')).toBe(false);
      });

      it('stops refreshing data', () => {
        jest.runOnlyPendingTimers();
        expectFetchDataToHaveBeenCalledTimes(1);
      });
    });
  });
});
