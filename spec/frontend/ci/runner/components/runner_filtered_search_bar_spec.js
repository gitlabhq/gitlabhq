import { GlFilteredSearch, GlSorting } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { assertProps } from 'helpers/assert_props';
import RunnerFilteredSearchBar from '~/ci/runner/components/runner_filtered_search_bar.vue';
import { statusTokenConfig } from '~/ci/runner/components/search_tokens/status_token_config';
import TagToken from '~/ci/runner/components/search_tokens/tag_token.vue';
import { tagTokenConfig } from '~/ci/runner/components/search_tokens/tag_token_config';
import {
  PARAM_KEY_STATUS,
  PARAM_KEY_TAG,
  STATUS_ONLINE,
  INSTANCE_TYPE,
  DEFAULT_MEMBERSHIP,
  DEFAULT_SORT,
  CONTACTED_DESC,
} from '~/ci/runner/constants';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearch from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';

const mockSearch = {
  runnerType: null,
  membership: DEFAULT_MEMBERSHIP,
  filters: [],
  pagination: { page: 1 },
  sort: DEFAULT_SORT,
};

describe('RunnerList', () => {
  let wrapper;

  const findFilteredSearch = () => wrapper.findComponent(FilteredSearch);
  const findGlFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);
  const findGlSorting = () => wrapper.findComponent(GlSorting);
  const getSortOptions = () => findGlSorting().props('sortOptions');
  const getSelectedSortOption = () => {
    const sortBy = findGlSorting().props('sortBy');
    return getSortOptions().find(({ value }) => sortBy === value)?.text;
  };

  const mockOtherSort = CONTACTED_DESC;
  const mockFilters = [
    { id: 1, type: PARAM_KEY_STATUS, value: { data: STATUS_ONLINE, operator: '=' } },
    { id: 2, type: FILTERED_SEARCH_TERM, value: { data: '' } },
  ];

  const expectToHaveLastEmittedInput = (value) => {
    const inputs = wrapper.emitted('input');
    expect(inputs[inputs.length - 1][0]).toEqual(value);
  };

  const defaultProps = { namespace: 'runners', tokens: [], value: mockSearch };

  const createComponent = ({ props = {}, options = {} } = {}) => {
    wrapper = shallowMountExtended(RunnerFilteredSearchBar, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        FilteredSearch,
        GlFilteredSearch,
      },
      ...options,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('binds a namespace to the filtered search', () => {
    expect(findFilteredSearch().props('namespace')).toBe('runners');
  });

  it('sets sorting options', () => {
    const SORT_OPTIONS_COUNT = 2;

    const sortOptionsProp = getSortOptions();
    expect(sortOptionsProp).toHaveLength(SORT_OPTIONS_COUNT);
    expect(sortOptionsProp[0].text).toBe('Created date');
    expect(sortOptionsProp[1].text).toBe('Last contact');
  });

  it('sets tokens to the filtered search', () => {
    createComponent({
      props: {
        tokens: [statusTokenConfig, tagTokenConfig],
      },
    });

    expect(findFilteredSearch().props('tokens')).toEqual([
      expect.objectContaining({
        type: PARAM_KEY_STATUS,
        token: BaseToken,
        options: expect.any(Array),
      }),
      expect.objectContaining({
        type: PARAM_KEY_TAG,
        token: TagToken,
      }),
    ]);
  });

  it('can be configured with null or undefined tokens, which are ignored', () => {
    createComponent({
      props: {
        tokens: [statusTokenConfig, null, undefined],
      },
    });

    expect(findFilteredSearch().props('tokens')).toEqual([statusTokenConfig]);
  });

  it('fails validation for v-model with the wrong shape', () => {
    expect(() => {
      assertProps(RunnerFilteredSearchBar, {
        ...defaultProps,
        value: { filters: 'wrong_filters', sort: 'sort' },
      });
    }).toThrow('Invalid prop: custom validator check failed');

    expect(() => {
      assertProps(RunnerFilteredSearchBar, { ...defaultProps, value: { sort: 'sort' } });
    }).toThrow('Invalid prop: custom validator check failed');
  });

  describe('when a search is preselected', () => {
    beforeEach(() => {
      createComponent({
        props: {
          value: {
            runnerType: INSTANCE_TYPE,
            membership: DEFAULT_MEMBERSHIP,
            sort: mockOtherSort,
            filters: mockFilters,
          },
        },
      });
    });

    it('filter values are shown', () => {
      expect(findGlFilteredSearch().props('value')).toMatchObject(mockFilters);
    });

    it('sort option is selected', () => {
      expect(getSelectedSortOption()).toBe('Last contact');
    });

    it('when the user sets a filter, the "search" preserves the other filters', async () => {
      findGlFilteredSearch().vm.$emit('input', mockFilters);
      findGlFilteredSearch().vm.$emit('submit');

      await nextTick();

      expectToHaveLastEmittedInput({
        runnerType: INSTANCE_TYPE,
        membership: DEFAULT_MEMBERSHIP,
        filters: mockFilters,
        sort: mockOtherSort,
        pagination: {},
      });
    });
  });

  it('when the user sets a filter, the "search" is emitted with filters', async () => {
    findGlFilteredSearch().vm.$emit('input', mockFilters);
    findGlFilteredSearch().vm.$emit('submit');

    await nextTick();

    expectToHaveLastEmittedInput({
      runnerType: null,
      membership: DEFAULT_MEMBERSHIP,
      filters: mockFilters,
      sort: DEFAULT_SORT,
      pagination: {},
    });
  });

  it('when the user sets a sorting method, the "search" is emitted with the sort', () => {
    findGlSorting().vm.$emit('sortByChange', 2);

    expectToHaveLastEmittedInput({
      runnerType: null,
      membership: DEFAULT_MEMBERSHIP,
      filters: [],
      sort: mockOtherSort,
      pagination: {},
    });
  });
});
