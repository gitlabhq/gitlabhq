import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import BoardFilteredSearch from '~/boards/components/board_filtered_search.vue';
import * as urlUtility from '~/lib/utils/url_utility';
import {
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_LABEL,
} from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBarRoot from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';
import { createStore } from '~/boards/stores';

Vue.use(Vuex);

describe('BoardFilteredSearch', () => {
  let wrapper;
  let store;
  const tokens = [
    {
      icon: 'labels',
      title: TOKEN_TITLE_LABEL,
      type: 'label',
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
      title: TOKEN_TITLE_AUTHOR,
      type: 'author',
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

  const createComponent = ({ initialFilterParams = {}, props = {} } = {}) => {
    store = createStore();
    wrapper = shallowMount(BoardFilteredSearch, {
      provide: { initialFilterParams, fullPath: '' },
      store,
      propsData: {
        ...props,
        tokens,
      },
    });
  };

  const findFilteredSearch = () => wrapper.findComponent(FilteredSearchBarRoot);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();

      jest.spyOn(store, 'dispatch').mockImplementation();
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

  describe('when eeFilters is not empty', () => {
    it('passes the correct initialFilterValue to FitleredSearchBarRoot', () => {
      createComponent({ props: { eeFilters: { labelName: ['label'] } } });

      expect(findFilteredSearch().props('initialFilterValue')).toEqual([
        { type: 'label', value: { data: 'label', operator: '=' } },
      ]);
    });
  });

  it('renders FilteredSearch', () => {
    createComponent();

    expect(findFilteredSearch().exists()).toBe(true);
  });

  describe('when searching', () => {
    beforeEach(() => {
      createComponent();

      jest.spyOn(wrapper.vm, 'performSearch').mockImplementation();
    });

    it('sets the url params to the correct results', async () => {
      const mockFilters = [
        { type: 'author', value: { data: 'root', operator: '=' } },
        { type: 'assignee', value: { data: 'root', operator: '=' } },
        { type: 'label', value: { data: 'label', operator: '=' } },
        { type: 'label', value: { data: 'label&2', operator: '=' } },
        { type: 'milestone', value: { data: 'New Milestone', operator: '=' } },
        { type: 'type', value: { data: 'INCIDENT', operator: '=' } },
        { type: 'weight', value: { data: '2', operator: '=' } },
        { type: 'iteration', value: { data: 'Any&3', operator: '=' } },
        { type: 'release', value: { data: 'v1.0.0', operator: '=' } },
        { type: 'health_status', value: { data: 'onTrack', operator: '=' } },
      ];
      jest.spyOn(urlUtility, 'updateHistory');
      findFilteredSearch().vm.$emit('onFilter', mockFilters);

      expect(urlUtility.updateHistory).toHaveBeenCalledWith({
        title: '',
        replace: true,
        url:
          'http://test.host/?author_username=root&label_name[]=label&label_name[]=label%262&assignee_username=root&milestone_title=New%20Milestone&iteration_id=Any&iteration_cadence_id=3&types=INCIDENT&weight=2&release_tag=v1.0.0&health_status=onTrack',
      });
    });

    describe('when assignee is passed a wildcard value', () => {
      const url = (arg) => `http://test.host/?assignee_id=${arg}`;

      it.each([
        ['None', url('None')],
        ['Any', url('Any')],
      ])('sets the url param %s', (assigneeParam, expected) => {
        const mockFilters = [{ type: 'assignee', value: { data: assigneeParam, operator: '=' } }];
        jest.spyOn(urlUtility, 'updateHistory');
        findFilteredSearch().vm.$emit('onFilter', mockFilters);

        expect(urlUtility.updateHistory).toHaveBeenCalledWith({
          title: '',
          replace: true,
          url: expected,
        });
      });
    });
  });

  describe('when url params are already set', () => {
    beforeEach(() => {
      createComponent({
        initialFilterParams: { authorUsername: 'root', labelName: ['label'], healthStatus: 'Any' },
      });

      jest.spyOn(store, 'dispatch');
    });

    it('passes the correct props to FilterSearchBar', () => {
      expect(findFilteredSearch().props('initialFilterValue')).toEqual([
        { type: 'author', value: { data: 'root', operator: '=' } },
        { type: 'label', value: { data: 'label', operator: '=' } },
        { type: 'health_status', value: { data: 'Any', operator: '=' } },
      ]);
    });
  });
});
