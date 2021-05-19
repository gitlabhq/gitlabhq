import { GlFilteredSearch } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { convertToFixedRange } from '~/lib/utils/datetime_range';
import LogAdvancedFilters from '~/logs/components/log_advanced_filters.vue';
import { TOKEN_TYPE_POD_NAME } from '~/logs/constants';
import { createStore } from '~/logs/stores';
import { OPERATOR_IS_ONLY } from '~/vue_shared/components/filtered_search_bar/constants';
import { defaultTimeRange } from '~/vue_shared/constants';
import { mockPods, mockSearch } from '../mock_data';

const module = 'environmentLogs';

describe('LogAdvancedFilters', () => {
  let store;
  let dispatch;
  let wrapper;
  let state;

  const findFilteredSearch = () => wrapper.find(GlFilteredSearch);
  const findTimeRangePicker = () => wrapper.find({ ref: 'dateTimePicker' });
  const getSearchToken = (type) =>
    findFilteredSearch()
      .props('availableTokens')
      .filter((token) => token.type === type)[0];

  const mockStateLoading = () => {
    state.timeRange.selected = defaultTimeRange;
    state.timeRange.current = convertToFixedRange(defaultTimeRange);
    state.pods.options = [];
    state.pods.current = null;
    state.logs.isLoading = true;
  };

  const mockStateWithData = () => {
    state.timeRange.selected = defaultTimeRange;
    state.timeRange.current = convertToFixedRange(defaultTimeRange);
    state.pods.options = mockPods;
    state.pods.current = null;
    state.logs.isLoading = false;
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

    expect(findFilteredSearch().exists()).toBe(true);
    expect(findTimeRangePicker().exists()).toBe(true);
  });

  it('displays search tokens', () => {
    initWrapper();

    expect(getSearchToken(TOKEN_TYPE_POD_NAME)).toMatchObject({
      title: 'Pod name',
      unique: true,
      operators: OPERATOR_IS_ONLY,
    });
  });

  describe('disabled state', () => {
    beforeEach(() => {
      mockStateLoading();
      initWrapper({
        disabled: true,
      });
    });

    it('displays disabled filters', () => {
      expect(findFilteredSearch().attributes('disabled')).toBeTruthy();
      expect(findTimeRangePicker().attributes('disabled')).toBeTruthy();
    });
  });

  describe('when the state is loading', () => {
    beforeEach(() => {
      mockStateLoading();
      initWrapper();
    });

    it('displays a disabled search', () => {
      expect(findFilteredSearch().attributes('disabled')).toBeTruthy();
    });

    it('displays an enable date filter', () => {
      expect(findTimeRangePicker().attributes('disabled')).toBeFalsy();
    });

    it('displays no pod options when no pods are available, so suggestions can be displayed', () => {
      expect(getSearchToken(TOKEN_TYPE_POD_NAME).options).toBe(null);
      expect(getSearchToken(TOKEN_TYPE_POD_NAME).loading).toBe(true);
    });
  });

  describe('when the state has data', () => {
    beforeEach(() => {
      mockStateWithData();
      initWrapper();
    });

    it('displays a single token for pods', () => {
      initWrapper();

      const tokens = findFilteredSearch().props('availableTokens');

      expect(tokens).toHaveLength(1);
      expect(tokens[0].type).toBe(TOKEN_TYPE_POD_NAME);
    });

    it('displays a enabled filters', () => {
      expect(findFilteredSearch().attributes('disabled')).toBeFalsy();
      expect(findTimeRangePicker().attributes('disabled')).toBeFalsy();
    });

    it('displays options in the pods token', () => {
      const { options } = getSearchToken(TOKEN_TYPE_POD_NAME);

      expect(options).toHaveLength(mockPods.length);
    });

    it('displays options in date time picker', () => {
      const options = findTimeRangePicker().props('options');

      expect(options).toEqual(expect.any(Array));
      expect(options.length).toBeGreaterThan(0);
    });

    describe('when the user interacts', () => {
      it('clicks on the search button, showFilteredLogs is dispatched', () => {
        findFilteredSearch().vm.$emit('submit', null);

        expect(dispatch).toHaveBeenCalledWith(`${module}/showFilteredLogs`, null);
      });

      it('clicks on the search button, showFilteredLogs is dispatched with null', () => {
        findFilteredSearch().vm.$emit('submit', [mockSearch]);

        expect(dispatch).toHaveBeenCalledWith(`${module}/showFilteredLogs`, [mockSearch]);
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
