import { GlIcon, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { defaultTimeRange } from '~/vue_shared/constants';
import { convertToFixedRange } from '~/lib/utils/datetime_range';
import { createStore } from '~/logs/stores';
import { mockPods, mockSearch } from '../mock_data';

import LogAdvancedFilters from '~/logs/components/log_advanced_filters.vue';

const module = 'environmentLogs';

describe('LogAdvancedFilters', () => {
  let store;
  let dispatch;
  let wrapper;
  let state;

  const findPodsDropdown = () => wrapper.find({ ref: 'podsDropdown' });
  const findPodsNoPodsText = () => wrapper.find({ ref: 'noPodsMsg' });
  const findPodsDropdownItems = () =>
    findPodsDropdown()
      .findAll(GlDropdownItem)
      .filter(item => !item.is('[disabled]'));
  const findPodsDropdownItemsSelected = () =>
    findPodsDropdownItems()
      .filter(item => {
        return !item.find(GlIcon).classes('invisible');
      })
      .at(0);
  const findSearchBox = () => wrapper.find({ ref: 'searchBox' });
  const findTimeRangePicker = () => wrapper.find({ ref: 'dateTimePicker' });

  const mockStateLoading = () => {
    state.timeRange.selected = defaultTimeRange;
    state.timeRange.current = convertToFixedRange(defaultTimeRange);
    state.pods.options = [];
    state.pods.current = null;
  };

  const mockStateWithData = () => {
    state.timeRange.selected = defaultTimeRange;
    state.timeRange.current = convertToFixedRange(defaultTimeRange);
    state.pods.options = mockPods;
    state.pods.current = null;
  };

  const initWrapper = (propsData = {}) => {
    wrapper = shallowMount(LogAdvancedFilters, {
      propsData: {
        ...propsData,
      },
      store,
    });
  };

  beforeEach(() => {
    store = createStore();
    state = store.state.environmentLogs;

    jest.spyOn(store, 'dispatch').mockResolvedValue();

    dispatch = store.dispatch;
  });

  afterEach(() => {
    store.dispatch.mockReset();

    if (wrapper) {
      wrapper.destroy();
    }
  });

  it('displays UI elements', () => {
    initWrapper();

    expect(wrapper.isVueInstance()).toBe(true);
    expect(wrapper.isEmpty()).toBe(false);

    expect(findPodsDropdown().exists()).toBe(true);
    expect(findSearchBox().exists()).toBe(true);
    expect(findTimeRangePicker().exists()).toBe(true);
  });

  describe('disabled state', () => {
    beforeEach(() => {
      mockStateLoading();
      initWrapper({
        disabled: true,
      });
    });

    it('displays disabled filters', () => {
      expect(findPodsDropdown().props('text')).toBe('All pods');
      expect(findPodsDropdown().attributes('disabled')).toBeTruthy();
      expect(findSearchBox().attributes('disabled')).toBeTruthy();
      expect(findTimeRangePicker().attributes('disabled')).toBeTruthy();
    });
  });

  describe('when the state is loading', () => {
    beforeEach(() => {
      mockStateLoading();
      initWrapper();
    });

    it('displays a enabled filters', () => {
      expect(findPodsDropdown().props('text')).toBe('All pods');
      expect(findPodsDropdown().attributes('disabled')).toBeFalsy();
      expect(findSearchBox().attributes('disabled')).toBeFalsy();
      expect(findTimeRangePicker().attributes('disabled')).toBeFalsy();
    });

    it('displays an empty pods dropdown', () => {
      expect(findPodsNoPodsText().exists()).toBe(true);
      expect(findPodsDropdownItems()).toHaveLength(0);
    });
  });

  describe('when the state has data', () => {
    beforeEach(() => {
      mockStateWithData();
      initWrapper();
    });

    it('displays an enabled pods dropdown', () => {
      expect(findPodsDropdown().attributes('disabled')).toBeFalsy();
      expect(findPodsDropdown().props('text')).toBe('All pods');
    });

    it('displays options in a pods dropdown', () => {
      const items = findPodsDropdownItems();
      expect(items).toHaveLength(mockPods.length + 1);
    });

    it('displays "all pods" selected in a pods dropdown', () => {
      const selected = findPodsDropdownItemsSelected();

      expect(selected.text()).toBe('All pods');
    });

    it('displays options in date time picker', () => {
      const options = findTimeRangePicker().props('options');

      expect(options).toEqual(expect.any(Array));
      expect(options.length).toBeGreaterThan(0);
    });

    describe('when the user interacts', () => {
      it('clicks on a all options, showPodLogs is dispatched with null', () => {
        const items = findPodsDropdownItems();
        items.at(0).vm.$emit('click');

        expect(dispatch).toHaveBeenCalledWith(`${module}/showPodLogs`, null);
      });

      it('clicks on a pod name, showPodLogs is dispatched with pod name', () => {
        const items = findPodsDropdownItems();
        const index = 2; // any pod

        items.at(index + 1).vm.$emit('click'); // skip "All pods" option

        expect(dispatch).toHaveBeenCalledWith(`${module}/showPodLogs`, mockPods[index]);
      });

      it('clicks on search, a serches is done', () => {
        expect(findSearchBox().attributes('disabled')).toBeFalsy();

        // input a query and click `search`
        findSearchBox().vm.$emit('input', mockSearch);
        findSearchBox().vm.$emit('submit');

        expect(dispatch).toHaveBeenCalledWith(`${module}/setSearch`, mockSearch);
      });

      it('selects a new time range', () => {
        expect(findTimeRangePicker().attributes('disabled')).toBeFalsy();

        const mockRange = { start: 'START_DATE', end: 'END_DATE' };
        findTimeRangePicker().vm.$emit('input', mockRange);

        expect(dispatch).toHaveBeenCalledWith(`${module}/setTimeRange`, mockRange);
      });
    });
  });
});
