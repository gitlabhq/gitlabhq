import { GlSearchBoxByClick } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import GlobalSearchTopbar from '~/search/topbar/components/app.vue';
import GroupFilter from '~/search/topbar/components/group_filter.vue';
import ProjectFilter from '~/search/topbar/components/project_filter.vue';

Vue.use(Vuex);

describe('GlobalSearchTopbar', () => {
  let wrapper;

  const actionSpies = {
    applyQuery: jest.fn(),
    setQuery: jest.fn(),
    preloadStoredFrequentItems: jest.fn(),
  };

  const createComponent = (initialState) => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
        ...initialState,
      },
      actions: actionSpies,
    });

    wrapper = shallowMount(GlobalSearchTopbar, {
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findGlSearchBox = () => wrapper.find(GlSearchBoxByClick);
  const findGroupFilter = () => wrapper.find(GroupFilter);
  const findProjectFilter = () => wrapper.find(ProjectFilter);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('Search box', () => {
      it('renders always', () => {
        expect(findGlSearchBox().exists()).toBe(true);
      });
    });

    describe.each`
      snippets                            | showFilters
      ${null}                             | ${true}
      ${{ query: { snippets: '' } }}      | ${true}
      ${{ query: { snippets: false } }}   | ${true}
      ${{ query: { snippets: true } }}    | ${false}
      ${{ query: { snippets: 'false' } }} | ${true}
      ${{ query: { snippets: 'true' } }}  | ${false}
    `('topbar filters', ({ snippets, showFilters }) => {
      beforeEach(() => {
        createComponent(snippets);
      });

      it(`does${showFilters ? '' : ' not'} render when snippets is ${JSON.stringify(
        snippets,
      )}`, () => {
        expect(findGroupFilter().exists()).toBe(showFilters);
        expect(findProjectFilter().exists()).toBe(showFilters);
      });
    });
  });

  describe('actions', () => {
    beforeEach(() => {
      createComponent();
    });

    it('clicking search button inside search box calls applyQuery', () => {
      findGlSearchBox().vm.$emit('submit', { preventDefault: () => {} });

      expect(actionSpies.applyQuery).toHaveBeenCalled();
    });
  });

  describe('onCreate', () => {
    beforeEach(() => {
      createComponent();
    });

    it('calls preloadStoredFrequentItems', () => {
      expect(actionSpies.preloadStoredFrequentItems).toHaveBeenCalled();
    });
  });
});
