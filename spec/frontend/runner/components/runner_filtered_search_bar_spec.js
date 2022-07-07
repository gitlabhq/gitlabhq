import { GlFilteredSearch, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerFilteredSearchBar from '~/runner/components/runner_filtered_search_bar.vue';
import { statusTokenConfig } from '~/runner/components/search_tokens/status_token_config';
import TagToken from '~/runner/components/search_tokens/tag_token.vue';
import { tagTokenConfig } from '~/runner/components/search_tokens/tag_token_config';
import { PARAM_KEY_STATUS, PARAM_KEY_TAG, STATUS_ONLINE, INSTANCE_TYPE } from '~/runner/constants';
import FilteredSearch from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';

describe('RunnerList', () => {
  let wrapper;

  const findFilteredSearch = () => wrapper.findComponent(FilteredSearch);
  const findGlFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);
  const findSortOptions = () => wrapper.findAllComponents(GlDropdownItem);

  const mockDefaultSort = 'CREATED_DESC';
  const mockOtherSort = 'CONTACTED_DESC';
  const mockFilters = [
    { type: PARAM_KEY_STATUS, value: { data: STATUS_ONLINE, operator: '=' } },
    { type: 'filtered-search-term', value: { data: '' } },
  ];

  const expectToHaveLastEmittedInput = (value) => {
    const inputs = wrapper.emitted('input');
    expect(inputs[inputs.length - 1][0]).toEqual(value);
  };

  const createComponent = ({ props = {}, options = {} } = {}) => {
    wrapper = shallowMountExtended(RunnerFilteredSearchBar, {
      propsData: {
        namespace: 'runners',
        tokens: [],
        value: {
          runnerType: null,
          filters: [],
          sort: mockDefaultSort,
        },
        ...props,
      },
      stubs: {
        FilteredSearch,
        GlFilteredSearch,
        GlDropdown,
        GlDropdownItem,
      },
      ...options,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('binds a namespace to the filtered search', () => {
    expect(findFilteredSearch().props('namespace')).toBe('runners');
  });

  it('sets sorting options', () => {
    const SORT_OPTIONS_COUNT = 2;

    expect(findSortOptions()).toHaveLength(SORT_OPTIONS_COUNT);
    expect(findSortOptions().at(0).text()).toBe('Created date');
    expect(findSortOptions().at(1).text()).toBe('Last contact');
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
      createComponent({ props: { value: { filters: 'wrong_filters', sort: 'sort' } } });
    }).toThrow('Invalid prop: custom validator check failed');

    expect(() => {
      createComponent({ props: { value: { sort: 'sort' } } });
    }).toThrow('Invalid prop: custom validator check failed');
  });

  describe('when a search is preselected', () => {
    beforeEach(() => {
      createComponent({
        props: {
          value: {
            runnerType: INSTANCE_TYPE,
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
      expect(
        findSortOptions()
          .filter((w) => w.props('isChecked'))
          .at(0)
          .text(),
      ).toEqual('Last contact');
    });

    it('when the user sets a filter, the "search" preserves the other filters', () => {
      findGlFilteredSearch().vm.$emit('input', mockFilters);
      findGlFilteredSearch().vm.$emit('submit');

      expectToHaveLastEmittedInput({
        runnerType: INSTANCE_TYPE,
        filters: mockFilters,
        sort: mockOtherSort,
        pagination: { page: 1 },
      });
    });
  });

  it('when the user sets a filter, the "search" is emitted with filters', () => {
    findGlFilteredSearch().vm.$emit('input', mockFilters);
    findGlFilteredSearch().vm.$emit('submit');

    expectToHaveLastEmittedInput({
      runnerType: null,
      filters: mockFilters,
      sort: mockDefaultSort,
      pagination: { page: 1 },
    });
  });

  it('when the user sets a sorting method, the "search" is emitted with the sort', () => {
    findSortOptions().at(1).vm.$emit('click');

    expectToHaveLastEmittedInput({
      runnerType: null,
      filters: [],
      sort: mockOtherSort,
      pagination: { page: 1 },
    });
  });
});
