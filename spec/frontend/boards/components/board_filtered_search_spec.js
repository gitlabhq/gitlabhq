import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import BoardFilteredSearch from '~/boards/components/board_filtered_search.vue';
import { createStore } from '~/boards/stores';
import * as urlUtility from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import FilteredSearchBarRoot from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';

Vue.use(Vuex);

describe('BoardFilteredSearch', () => {
  let wrapper;
  let store;
  const tokens = [
    {
      icon: 'labels',
      title: __('Label'),
      type: 'label_name',
      operators: [
        { value: '=', description: 'is' },
        { value: '!=', description: 'is not' },
      ],
      token: LabelToken,
      unique: false,
      symbol: '~',
      fetchLabels: () => new Promise(() => {}),
    },
    {
      icon: 'pencil',
      title: __('Author'),
      type: 'author_username',
      operators: [
        { value: '=', description: 'is' },
        { value: '!=', description: 'is not' },
      ],
      symbol: '@',
      token: AuthorToken,
      unique: true,
      fetchAuthors: () => new Promise(() => {}),
    },
  ];

  const createComponent = ({ initialFilterParams = {} } = {}) => {
    wrapper = shallowMount(BoardFilteredSearch, {
      provide: { initialFilterParams, fullPath: '' },
      store,
      propsData: {
        tokens,
      },
    });
  };

  const findFilteredSearch = () => wrapper.findComponent(FilteredSearchBarRoot);

  beforeEach(() => {
    // this needed for actions call for performSearch
    window.gon = { features: {} };
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(() => {
      store = createStore();

      jest.spyOn(store, 'dispatch');

      createComponent();
    });

    it('renders FilteredSearch', () => {
      expect(findFilteredSearch().exists()).toBe(true);
    });

    it('passes the correct tokens to FilteredSearch', () => {
      expect(findFilteredSearch().props('tokens')).toEqual(tokens);
    });

    describe('when onFilter is emitted', () => {
      it('calls performSearch', () => {
        findFilteredSearch().vm.$emit('onFilter', [{ value: { data: '' } }]);

        expect(store.dispatch).toHaveBeenCalledWith('performSearch');
      });

      it('calls historyPushState', () => {
        jest.spyOn(urlUtility, 'updateHistory');
        findFilteredSearch().vm.$emit('onFilter', [{ value: { data: 'searchQuery' } }]);

        expect(urlUtility.updateHistory).toHaveBeenCalledWith({
          replace: true,
          title: '',
          url: 'http://test.host/',
        });
      });
    });
  });

  describe('when searching', () => {
    beforeEach(() => {
      store = createStore();

      createComponent();

      jest.spyOn(wrapper.vm, 'performSearch').mockImplementation();
    });

    it('sets the url params to the correct results', async () => {
      const mockFilters = [
        { type: 'author_username', value: { data: 'root', operator: '=' } },
        { type: 'label_name', value: { data: 'label', operator: '=' } },
        { type: 'label_name', value: { data: 'label2', operator: '=' } },
      ];
      jest.spyOn(urlUtility, 'updateHistory');
      findFilteredSearch().vm.$emit('onFilter', mockFilters);

      expect(urlUtility.updateHistory).toHaveBeenCalledWith({
        title: '',
        replace: true,
        url: 'http://test.host/?author_username=root&label_name[]=label&label_name[]=label2',
      });
    });
  });

  describe('when url params are already set', () => {
    beforeEach(() => {
      store = createStore();

      jest.spyOn(store, 'dispatch');

      createComponent({ initialFilterParams: { authorUsername: 'root', labelName: ['label'] } });
    });

    it('passes the correct props to FilterSearchBar', () => {
      expect(findFilteredSearch().props('initialFilterValue')).toEqual([
        { type: 'author_username', value: { data: 'root', operator: '=' } },
        { type: 'label_name', value: { data: 'label', operator: '=' } },
      ]);
    });
  });
});
