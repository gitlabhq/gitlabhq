import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import BoardFilteredSearch from '~/boards/components/board_filtered_search.vue';
import * as urlUtility from '~/lib/utils/url_utility';
import {
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_LABEL,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_HEALTH,
  TOKEN_TYPE_ITERATION,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_TYPE,
  TOKEN_TYPE_WEIGHT,
} from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBarRoot from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';
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
      type: TOKEN_TYPE_LABEL,
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
      type: TOKEN_TYPE_AUTHOR,
      operators: [
        { value: '=', description: 'is' },
        { value: '!=', description: 'is not' },
      ],
      symbol: '@',
      token: UserToken,
      unique: true,
      fetchUsers: () => new Promise(() => {}),
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
        { type: TOKEN_TYPE_LABEL, value: { data: 'label', operator: '=' } },
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
        { type: TOKEN_TYPE_AUTHOR, value: { data: 'root', operator: '=' } },
        { type: TOKEN_TYPE_ASSIGNEE, value: { data: 'root', operator: '=' } },
        { type: TOKEN_TYPE_LABEL, value: { data: 'label', operator: '=' } },
        { type: TOKEN_TYPE_LABEL, value: { data: 'label&2', operator: '=' } },
        { type: TOKEN_TYPE_MILESTONE, value: { data: 'New Milestone', operator: '=' } },
        { type: TOKEN_TYPE_TYPE, value: { data: 'INCIDENT', operator: '=' } },
        { type: TOKEN_TYPE_WEIGHT, value: { data: '2', operator: '=' } },
        { type: TOKEN_TYPE_ITERATION, value: { data: 'Any&3', operator: '=' } },
        { type: TOKEN_TYPE_RELEASE, value: { data: 'v1.0.0', operator: '=' } },
        { type: TOKEN_TYPE_HEALTH, value: { data: 'onTrack', operator: '=' } },
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
        const mockFilters = [
          { type: TOKEN_TYPE_ASSIGNEE, value: { data: assigneeParam, operator: '=' } },
        ];
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
        { type: TOKEN_TYPE_AUTHOR, value: { data: 'root', operator: '=' } },
        { type: TOKEN_TYPE_LABEL, value: { data: 'label', operator: '=' } },
        { type: TOKEN_TYPE_HEALTH, value: { data: 'Any', operator: '=' } },
      ]);
    });
  });
});
