import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import {
  filterMilestones,
  filterLabels,
} from 'jest/vue_shared/components/filtered_search_bar/store/modules/filters/mock_data';
import FilterBar from '~/analytics/cycle_analytics/components/filter_bar.vue';
import storeConfig from '~/analytics/cycle_analytics/store';
import * as commonUtils from '~/lib/utils/common_utils';
import * as urlUtils from '~/lib/utils/url_utility';
import {
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import * as utils from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import initialFiltersState from '~/vue_shared/components/filtered_search_bar/store/modules/filters/state';
import UrlSync from '~/vue_shared/components/url_sync.vue';

Vue.use(Vuex);

const milestoneTokenType = TOKEN_TYPE_MILESTONE;
const labelsTokenType = TOKEN_TYPE_LABEL;
const authorTokenType = TOKEN_TYPE_AUTHOR;
const assigneesTokenType = TOKEN_TYPE_ASSIGNEE;

const initialFilterBarState = {
  selectedMilestone: null,
  selectedAuthor: null,
  selectedAssigneeList: null,
  selectedLabelList: null,
};

const defaultParams = {
  milestone_title: null,
  'not[milestone_title]': null,
  author_username: null,
  'not[author_username]': null,
  assignee_username: null,
  'not[assignee_username]': null,
  label_name: null,
  'not[label_name]': null,
};

async function shouldMergeUrlParams(wrapper, result) {
  await nextTick();
  expect(urlUtils.mergeUrlParams).toHaveBeenCalledWith(result, window.location.href, {
    spreadArrays: true,
  });
  expect(commonUtils.historyPushState).toHaveBeenCalled();
}

describe('Filter bar', () => {
  let wrapper;
  let store;
  let mock;

  let setFiltersMock;

  const createStore = (initialState = {}) => {
    setFiltersMock = jest.fn();

    return new Vuex.Store({
      modules: {
        filters: {
          namespaced: true,
          state: {
            ...initialFiltersState(),
            ...initialState,
          },
          actions: {
            setFilters: setFiltersMock,
          },
        },
      },
    });
  };

  const createComponent = (initialStore) => {
    return shallowMount(FilterBar, {
      store: initialStore,
      propsData: {
        namespacePath: 'foo',
      },
      stubs: {
        UrlSync,
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  const selectedMilestone = [filterMilestones[0]];
  const selectedLabelList = [filterLabels[0]];

  const findFilteredSearch = () => wrapper.findComponent(FilteredSearchBar);
  const getSearchToken = (type) =>
    findFilteredSearch()
      .props('tokens')
      .find((token) => token.type === type);

  describe('default', () => {
    beforeEach(() => {
      store = createStore();
      wrapper = createComponent(store);
    });

    it('renders FilteredSearchBar component', () => {
      expect(findFilteredSearch().exists()).toBe(true);
    });

    it('passes the `terms-as-tokens` prop', () => {
      expect(findFilteredSearch().props('termsAsTokens')).toBe(true);
    });
  });

  describe('when the state has data', () => {
    beforeEach(() => {
      store = createStore({
        milestones: { data: selectedMilestone },
        labels: { data: selectedLabelList },
        authors: { data: [] },
        assignees: { data: [] },
      });
      wrapper = createComponent(store);
    });

    it('displays the milestone and label token', () => {
      const tokens = findFilteredSearch().props('tokens');

      expect(tokens).toHaveLength(4);
      expect(tokens[0].type).toBe(milestoneTokenType);
      expect(tokens[1].type).toBe(labelsTokenType);
      expect(tokens[2].type).toBe(authorTokenType);
      expect(tokens[3].type).toBe(assigneesTokenType);
    });

    it('provides the initial milestone token', () => {
      const { initialMilestones: milestoneToken } = getSearchToken(milestoneTokenType);

      expect(milestoneToken).toHaveLength(selectedMilestone.length);
    });

    it('provides the initial label token', () => {
      const { initialLabels: labelToken } = getSearchToken(labelsTokenType);

      expect(labelToken).toHaveLength(selectedLabelList.length);
    });
  });

  describe('when the user interacts', () => {
    beforeEach(() => {
      store = createStore({
        milestones: { data: filterMilestones },
        labels: { data: filterLabels },
      });
      wrapper = createComponent(store);
      jest.spyOn(utils, 'processFilters');
    });

    it('clicks on the search button, setFilters is dispatched', () => {
      const filters = [
        { type: TOKEN_TYPE_MILESTONE, value: { data: selectedMilestone[0].title, operator: '=' } },
        { type: TOKEN_TYPE_LABEL, value: { data: selectedLabelList[0].title, operator: '=' } },
      ];

      findFilteredSearch().vm.$emit('onFilter', filters);

      expect(utils.processFilters).toHaveBeenCalledWith(filters);

      expect(setFiltersMock).toHaveBeenCalledWith(expect.anything(), {
        selectedLabelList: [{ value: selectedLabelList[0].title, operator: '=' }],
        selectedMilestone: { value: selectedMilestone[0].title, operator: '=' },
        selectedAssigneeList: [],
        selectedAuthor: null,
      });
    });
  });

  describe.each([
    ['selectedMilestone', 'milestone_title', { value: '12.0', operator: '=' }, '12.0'],
    ['selectedAuthor', 'author_username', { value: 'rootUser', operator: '=' }, 'rootUser'],
    [
      'selectedLabelList',
      'label_name',
      [
        { value: 'Afternix', operator: '=' },
        { value: 'Brouceforge', operator: '=' },
      ],
      ['Afternix', 'Brouceforge'],
    ],
    [
      'selectedAssigneeList',
      'assignee_username',
      [
        { value: 'rootUser', operator: '=' },
        { value: 'secondaryUser', operator: '=' },
      ],
      ['rootUser', 'secondaryUser'],
    ],
    // eslint-disable-next-line max-params
  ])('with a %s updates the %s url parameter', (stateKey, paramKey, payload, result) => {
    beforeEach(() => {
      commonUtils.historyPushState = jest.fn();
      urlUtils.mergeUrlParams = jest.fn();

      mock = new MockAdapter(axios);
      store = storeConfig();
      wrapper = createComponent(store);

      store.dispatch('filters/setFilters', {
        ...initialFilterBarState,
        [stateKey]: payload,
      });
    });
    it(`sets the ${paramKey} url parameter`, () => {
      return shouldMergeUrlParams(wrapper, {
        ...defaultParams,
        [paramKey]: result,
      });
    });
  });
});
