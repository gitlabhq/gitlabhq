import { GlFilteredSearch, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import RunnerFilteredSearchBar from '~/runner/components/runner_filtered_search_bar.vue';
import TagToken from '~/runner/components/search_tokens/tag_token.vue';
import { PARAM_KEY_STATUS, PARAM_KEY_RUNNER_TYPE, PARAM_KEY_TAG } from '~/runner/constants';
import FilteredSearch from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';

describe('RunnerList', () => {
  let wrapper;

  const findFilteredSearch = () => wrapper.findComponent(FilteredSearch);
  const findGlFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);
  const findSortOptions = () => wrapper.findAllComponents(GlDropdownItem);
  const findActiveRunnersMessage = () => wrapper.findByTestId('active-runners-message');

  const mockDefaultSort = 'CREATED_DESC';
  const mockOtherSort = 'CONTACTED_DESC';
  const mockFilters = [
    { type: PARAM_KEY_STATUS, value: { data: 'ACTIVE', operator: '=' } },
    { type: 'filtered-search-term', value: { data: '' } },
  ];
  const mockActiveRunnersCount = 2;

  const createComponent = ({ props = {}, options = {} } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(RunnerFilteredSearchBar, {
        propsData: {
          namespace: 'runners',
          value: {
            filters: [],
            sort: mockDefaultSort,
          },
          activeRunnersCount: mockActiveRunnersCount,
          ...props,
        },
        stubs: {
          FilteredSearch,
          GlFilteredSearch,
          GlDropdown,
          GlDropdownItem,
        },
        ...options,
      }),
    );
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

  it('Displays an active runner count', () => {
    expect(findActiveRunnersMessage().text()).toBe(
      `Runners currently online: ${mockActiveRunnersCount}`,
    );
  });

  it('Displays a large active runner count', () => {
    createComponent({ props: { activeRunnersCount: 2000 } });

    expect(findActiveRunnersMessage().text()).toBe('Runners currently online: 2,000');
  });

  it('sets sorting options', () => {
    const SORT_OPTIONS_COUNT = 2;

    expect(findSortOptions()).toHaveLength(SORT_OPTIONS_COUNT);
    expect(findSortOptions().at(0).text()).toBe('Created date');
    expect(findSortOptions().at(1).text()).toBe('Last contact');
  });

  it('sets tokens', () => {
    expect(findFilteredSearch().props('tokens')).toEqual([
      expect.objectContaining({
        type: PARAM_KEY_STATUS,
        token: BaseToken,
        options: expect.any(Array),
      }),
      expect.objectContaining({
        type: PARAM_KEY_RUNNER_TYPE,
        token: BaseToken,
        options: expect.any(Array),
      }),
      expect.objectContaining({
        type: PARAM_KEY_TAG,
        token: TagToken,
      }),
    ]);
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
            sort: mockOtherSort,
            filters: mockFilters,
          },
        },
      });
    });

    it('filter values are shown', () => {
      expect(findGlFilteredSearch().props('value')).toEqual(mockFilters);
    });

    it('sort option is selected', () => {
      expect(
        findSortOptions()
          .filter((w) => w.props('isChecked'))
          .at(0)
          .text(),
      ).toEqual('Last contact');
    });
  });

  it('when the user sets a filter, the "search" is emitted with filters', () => {
    findGlFilteredSearch().vm.$emit('input', mockFilters);
    findGlFilteredSearch().vm.$emit('submit');

    expect(wrapper.emitted('input')[0]).toEqual([
      {
        filters: mockFilters,
        sort: mockDefaultSort,
        pagination: { page: 1 },
      },
    ]);
  });

  it('when the user sets a sorting method, the "search" is emitted with the sort', () => {
    findSortOptions().at(1).vm.$emit('click');

    expect(wrapper.emitted('input')[0]).toEqual([
      {
        filters: [],
        sort: mockOtherSort,
        pagination: { page: 1 },
      },
    ]);
  });
});
