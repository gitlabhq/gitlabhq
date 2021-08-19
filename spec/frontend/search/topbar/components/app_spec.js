import { GlForm, GlSearchBoxByType, GlButton } from '@gitlab/ui';
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

  const findTopbarForm = () => wrapper.find(GlForm);
  const findGlSearchBox = () => wrapper.find(GlSearchBoxByType);
  const findGroupFilter = () => wrapper.find(GroupFilter);
  const findProjectFilter = () => wrapper.find(ProjectFilter);
  const findSearchButton = () => wrapper.find(GlButton);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders Topbar Form always', () => {
      expect(findTopbarForm().exists()).toBe(true);
    });

    describe('Search box', () => {
      it('renders always', () => {
        expect(findGlSearchBox().exists()).toBe(true);
      });

      describe('onSearch', () => {
        const testSearch = 'test search';

        beforeEach(() => {
          findGlSearchBox().vm.$emit('input', testSearch);
        });

        it('calls setQuery when input event is fired from GlSearchBoxByType', () => {
          expect(actionSpies.setQuery).toHaveBeenCalledWith(expect.any(Object), {
            key: 'search',
            value: testSearch,
          });
        });
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

    it('renders SearchButton always', () => {
      expect(findSearchButton().exists()).toBe(true);
    });
  });

  describe('actions', () => {
    beforeEach(() => {
      createComponent();
    });

    it('clicking SearchButton calls applyQuery', () => {
      findTopbarForm().vm.$emit('submit', { preventDefault: () => {} });

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
