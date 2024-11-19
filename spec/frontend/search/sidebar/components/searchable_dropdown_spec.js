import { GlCollapsibleListbox } from '@gitlab/ui';
import { cloneDeep } from 'lodash';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import waitForPromises from 'helpers/wait_for_promises';
import { MOCK_GROUPS, MOCK_QUERY } from 'jest/search/mock_data';
import SearchableDropdown from '~/search/sidebar/components/shared/searchable_dropdown.vue';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

Vue.use(Vuex);

describe('Global Search Searchable Dropdown', () => {
  let wrapper;

  const defaultProps = {
    headerText: 'Filter results by group',
    name: 'name',
    fullName: 'full_name',
    loading: false,
    selectedItem: {
      id: null,
      name: 'Any',
      name_with_namespace: 'Any',
    },
    items: [],
    frequentItems: [{ ...MOCK_GROUPS[0] }],
    searchHandler: jest.fn(),
  };

  const createComponent = (initialState, props) => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
        ...initialState,
      },
    });

    wrapper = shallowMount(SearchableDropdown, {
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findGlDropdown = () => wrapper.findComponent(GlCollapsibleListbox);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders GlDropdown', () => {
      expect(findGlDropdown().exists()).toBe(true);
    });

    const propItems = [
      {
        text: '',
        options: [
          {
            value: 'Any',
            text: 'Any',
            id: null,
            name: 'Any',
            name_with_namespace: 'Any',
          },
        ],
      },
      {
        text: 'Frequently searched',
        options: [{ value: MOCK_GROUPS[0].id, text: MOCK_GROUPS[0].full_name, ...MOCK_GROUPS[0] }],
      },
      {
        text: 'All available groups',
        options: [{ value: MOCK_GROUPS[1].id, text: MOCK_GROUPS[1].full_name, ...MOCK_GROUPS[1] }],
      },
    ];

    beforeEach(() => {
      createComponent({}, { items: MOCK_GROUPS });
    });

    it('contains correct set of items', () => {
      expect(findGlDropdown().props('items')).toStrictEqual(propItems);
    });

    it('renders searchable prop', () => {
      expect(findGlDropdown().props('searchable')).toBe(true);
    });

    describe('events', () => {
      it('emits select', () => {
        findGlDropdown().vm.$emit('select', 1);
        expect(cloneDeep(wrapper.emitted('change')[0][0])).toStrictEqual(MOCK_GROUPS[0]);
      });

      it('emits reset', () => {
        findGlDropdown().vm.$emit('reset');
        expect(cloneDeep(wrapper.emitted('change')[0][0])).toStrictEqual({
          id: null,
          name: 'Any',
          name_with_namespace: 'Any',
        });
      });

      it('emits first-open', () => {
        findGlDropdown().vm.$emit('shown');
        expect(wrapper.emitted('first-open')).toHaveLength(1);
        findGlDropdown().vm.$emit('shown');
        expect(wrapper.emitted('first-open')).toHaveLength(1);
      });
    });
  });

  describe('when @search is emitted', () => {
    const search = 'test';

    beforeEach(async () => {
      createComponent();
      findGlDropdown().vm.$emit('search', search);

      jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
      await waitForPromises();
    });

    it('calls fetchGroups with the search paramter', () => {
      expect(defaultProps.searchHandler).toHaveBeenCalledTimes(1);
      expect(defaultProps.searchHandler).toHaveBeenCalledWith(search);
    });
  });
});
