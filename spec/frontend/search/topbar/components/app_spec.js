import { GlSearchBoxByType, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import { stubComponent } from 'helpers/stub_component';
import GlobalSearchTopbar from '~/search/topbar/components/app.vue';
import GroupFilter from '~/search/topbar/components/group_filter.vue';
import ProjectFilter from '~/search/topbar/components/project_filter.vue';
import MarkdownDrawer from '~/vue_shared/components/markdown_drawer/markdown_drawer.vue';
import SearchTypeIndicator from '~/search/topbar/components/search_type_indicator.vue';

import {
  SYNTAX_OPTIONS_ADVANCED_DOCUMENT,
  SYNTAX_OPTIONS_ZOEKT_DOCUMENT,
} from '~/search/topbar/constants';

Vue.use(Vuex);

describe('GlobalSearchTopbar', () => {
  let wrapper;

  const actionSpies = {
    applyQuery: jest.fn(),
    setQuery: jest.fn(),
    preloadStoredFrequentItems: jest.fn(),
  };

  const createComponent = (initialState = {}, defaultBranchName = '', stubs = {}) => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
        ...initialState,
      },
      actions: actionSpies,
    });

    wrapper = shallowMount(GlobalSearchTopbar, {
      store,
      propsData: { defaultBranchName },
      stubs,
    });
  };

  const findGlSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findGroupFilter = () => wrapper.findComponent(GroupFilter);
  const findProjectFilter = () => wrapper.findComponent(ProjectFilter);
  const findSyntaxOptionButton = () => wrapper.findComponent(GlButton);
  const findSyntaxOptionDrawer = () => wrapper.findComponent(MarkdownDrawer);
  const findSearchTypeIndicator = () => wrapper.findComponent(SearchTypeIndicator);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('always renders Search box', () => {
      expect(findGlSearchBox().exists()).toBe(true);
    });

    it('always renders Search indicator', () => {
      expect(findSearchTypeIndicator().exists()).toBe(true);
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

    describe.each`
      searchType    | showSyntaxOptions
      ${'basic'}    | ${false}
      ${'advanced'} | ${true}
      ${'zoekt'}    | ${true}
    `('syntax options drawer with searchType: $searchType', ({ searchType, showSyntaxOptions }) => {
      beforeEach(() => {
        createComponent({ query: { repository_ref: '' }, searchType });
      });

      it('renders button correctly', () => {
        expect(findSyntaxOptionButton().exists()).toBe(showSyntaxOptions);
      });

      it('renders drawer correctly', () => {
        expect(findSyntaxOptionDrawer().exists()).toBe(showSyntaxOptions);
      });
    });

    describe.each`
      searchType    | documentPath
      ${'advanced'} | ${SYNTAX_OPTIONS_ADVANCED_DOCUMENT}
      ${'zoekt'}    | ${SYNTAX_OPTIONS_ZOEKT_DOCUMENT}
    `('syntax options drawer with searchType: $searchType', ({ searchType, documentPath }) => {
      beforeEach(() => {
        createComponent({ query: { repository_ref: '' }, searchType });
      });

      it('renders drawer with correct document', () => {
        expect(findSyntaxOptionDrawer()?.attributes('documentpath')).toBe(documentPath);
      });
    });

    describe('actions', () => {
      it('dispatched correct click action', () => {
        const drawerToggleSpy = jest.fn();

        createComponent({ query: { repository_ref: '' }, searchType: 'advanced' }, '', {
          MarkdownDrawer: stubComponent(MarkdownDrawer, {
            methods: { toggleDrawer: drawerToggleSpy },
          }),
        });

        findSyntaxOptionButton().vm.$emit('click');
        expect(drawerToggleSpy).toHaveBeenCalled();
      });
    });

    describe.each`
      state                                                              | defaultBranchName | hasSyntaxOptions
      ${{ query: { repository_ref: '' }, searchType: 'basic' }}          | ${'master'}       | ${false}
      ${{ query: { repository_ref: 'v0.1' }, searchType: 'basic' }}      | ${''}             | ${false}
      ${{ query: { repository_ref: 'master' }, searchType: 'basic' }}    | ${'master'}       | ${false}
      ${{ query: { repository_ref: 'master' }, searchType: 'advanced' }} | ${''}             | ${false}
      ${{ query: { repository_ref: '' }, searchType: 'advanced' }}       | ${'master'}       | ${true}
      ${{ query: { repository_ref: 'v0.1' }, searchType: 'advanced' }}   | ${''}             | ${false}
      ${{ query: { repository_ref: 'master' }, searchType: 'advanced' }} | ${'master'}       | ${true}
      ${{ query: { repository_ref: 'master' }, searchType: 'zoekt' }}    | ${'master'}       | ${true}
    `(
      `the syntax option based on component state`,
      ({ state, defaultBranchName, hasSyntaxOptions }) => {
        beforeEach(() => {
          createComponent({ ...state }, defaultBranchName);
        });

        describe(`repository: ${state.query.repository_ref}, searchType: ${state.searchType}`, () => {
          it(`renders correctly button`, () => {
            expect(findSyntaxOptionButton().exists()).toBe(hasSyntaxOptions);
          });

          it(`renders correctly drawer when branch name is ${state.query.repository_ref}`, () => {
            expect(findSyntaxOptionDrawer().exists()).toBe(hasSyntaxOptions);
          });
        });
      },
    );
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
