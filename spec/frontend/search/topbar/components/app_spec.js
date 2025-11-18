import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import { stubComponent } from 'helpers/stub_component';
import GlobalSearchTopbar from '~/search/topbar/components/app.vue';
import MarkdownDrawer from '~/vue_shared/components/markdown_drawer/markdown_drawer.vue';
import SearchTypeIndicator from '~/search/topbar/components/search_type_indicator.vue';
import GlobalSearchInput from '~/search/topbar/components/global_search_input.vue';
import * as urlUtils from '~/lib/utils/url_utility';
import * as storeUtils from '~/search/store/utils';
import {
  SYNTAX_OPTIONS_ADVANCED_DOCUMENT,
  SYNTAX_OPTIONS_ZOEKT_DOCUMENT,
} from '~/search/topbar/constants';
import { LS_REGEX_HANDLE } from '~/search/store/constants';

Vue.use(Vuex);

jest.mock('~/search/store/utils', () => ({
  LS_REGEX_HANDLE: jest.fn(() => 'test'),
  setDataToLS: jest.fn(),
}));

describe('GlobalSearchTopbar', () => {
  let wrapper;

  const actionSpies = {
    applyQuery: jest.fn(),
    setQuery: jest.fn(),
    preloadStoredFrequentItems: jest.fn(),
  };

  const getterSpies = {
    currentScope: jest.fn(),
  };

  const createComponent = ({ initialState = {}, stubs = {}, featureFlag = {} } = {}) => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
        ...initialState,
      },
      actions: actionSpies,
      getters: getterSpies,
    });

    wrapper = shallowMount(GlobalSearchTopbar, {
      store,
      stubs,
      provide: {
        glFeatures: featureFlag,
      },
    });
  };

  const findGlSearchBox = () => wrapper.findComponent(GlobalSearchInput);
  const findSyntaxOptionButton = () => wrapper.findComponent(GlButton);
  const findSyntaxOptionDrawer = () => wrapper.findComponent(MarkdownDrawer);
  const findSearchTypeIndicator = () => wrapper.findComponent(SearchTypeIndicator);
  const findRegularExpressionToggle = () =>
    wrapper.findComponent('[data-testid="reqular-expression-toggle"]');

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    describe.each`
      searchType    | hasRegexSearch
      ${'basic'}    | ${undefined}
      ${'advanced'} | ${undefined}
      ${'zoekt'}    | ${'true'}
    `('Seachbox options for searchType: $searchType', ({ searchType, hasRegexSearch }) => {
      beforeEach(() => {
        createComponent({
          initialState: {
            query: { repository_ref: 'master' },
            searchType,
            defaultBranchName: 'master',
          },
        });
      });

      it('always renders Search box', () => {
        expect(findGlSearchBox().exists()).toBe(true);
      });

      it('shows regular expression button', () => {
        expect(findGlSearchBox().attributes('regexbuttonisvisible')).toBe(hasRegexSearch);
      });
    });

    it('always renders Search indicator', () => {
      expect(findSearchTypeIndicator().exists()).toBe(true);
    });

    describe.each`
      searchType    | showSyntaxOptions
      ${'basic'}    | ${false}
      ${'advanced'} | ${true}
      ${'zoekt'}    | ${true}
    `('syntax options drawer with searchType: $searchType', ({ searchType, showSyntaxOptions }) => {
      beforeEach(() => {
        createComponent({ initialState: { query: { repository_ref: '' }, searchType } });
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
        createComponent({ initialState: { query: { repository_ref: '' }, searchType } });
      });

      it('renders drawer with correct document', () => {
        expect(findSyntaxOptionDrawer()?.attributes('documentpath')).toBe(documentPath);
      });
    });

    describe('actions', () => {
      it('dispatched correct click action', () => {
        const drawerToggleSpy = jest.fn();

        createComponent({
          initialState: { query: { repository_ref: '' }, searchType: 'advanced' },
          stubs: {
            MarkdownDrawer: stubComponent(MarkdownDrawer, {
              methods: { toggleDrawer: drawerToggleSpy },
            }),
          },
        });

        findSyntaxOptionButton().vm.$emit('click');
        expect(drawerToggleSpy).toHaveBeenCalled();
      });
    });

    describe.each`
      state                                                                                                                                                  | hasSyntaxOptions
      ${{ query: { repository_ref: '' }, searchType: 'basic', searchLevel: 'project', defaultBranchName: 'master' }}                                         | ${false}
      ${{ query: { repository_ref: 'v0.1' }, searchType: 'basic', searchLevel: 'project', defaultBranchName: '' }}                                           | ${false}
      ${{ query: { repository_ref: 'master' }, searchType: 'basic', searchLevel: 'project', defaultBranchName: 'master' }}                                   | ${false}
      ${{ query: { repository_ref: 'test' }, searchType: 'advanced', searchLevel: 'project', defaultBranchName: '', projectInitialJson: { id: 1 } }}         | ${false}
      ${{ query: { repository_ref: '' }, searchType: 'advanced', searchLevel: 'project', defaultBranchName: 'master', projectInitialJson: { id: 1 } }}       | ${true}
      ${{ query: { repository_ref: 'v0.1' }, searchType: 'advanced', searchLevel: 'project', defaultBranchName: '', projectInitialJson: { id: 1 } }}         | ${false}
      ${{ query: { repository_ref: 'master' }, searchType: 'advanced', searchLevel: 'project', defaultBranchName: 'master', projectInitialJson: { id: 1 } }} | ${true}
      ${{ query: { repository_ref: 'master' }, searchType: 'zoekt', searchLevel: 'project', defaultBranchName: 'master', projectInitialJson: { id: 1 } }}    | ${true}
    `(`the syntax option based on component state`, ({ state, hasSyntaxOptions }) => {
      beforeEach(() => {
        createComponent({
          initialState: { ...state },
        });
      });

      describe(`repository: ${state.query.repository_ref}, searchType: ${state.searchType}, defaultBranchName: ${state.defaultBranchName}`, () => {
        it(`renders correctly button`, () => {
          expect(findSyntaxOptionButton().exists()).toBe(hasSyntaxOptions);
        });

        it(`renders correctly drawer when branch name is ${state.query.repository_ref}`, () => {
          expect(findSyntaxOptionDrawer().exists()).toBe(hasSyntaxOptions);
        });
      });
    });
  });

  describe('actions', () => {
    describe.each`
      search    | reload
      ${''}     | ${0}
      ${'test'} | ${1}
    `('clicking regular expression button', ({ search, reload }) => {
      beforeEach(() => {
        createComponent({
          initialState: { query: { search }, searchType: 'zoekt' },
          stubs: { GlobalSearchInput },
        });
      });

      it(`calls setQuery and ${!reload ? 'NOT ' : ''}applyQuery if there is a search term`, () => {
        findRegularExpressionToggle().vm.$emit('click');
        expect(actionSpies.setQuery).toHaveBeenCalled();
        expect(actionSpies.applyQuery).toHaveBeenCalledTimes(reload);
      });
    });

    describe('onCreate', () => {
      it('calls preloadStoredFrequentItems', () => {
        createComponent();

        expect(actionSpies.preloadStoredFrequentItems).toHaveBeenCalled();
      });

      it('sets regexEnabled state to true if `regex=true` is present in query params', () => {
        jest.spyOn(urlUtils, 'getParameterByName').mockReturnValue('true');

        createComponent({
          initialState: { query: { search: 'test' }, searchType: 'zoekt' },
          stubs: { GlobalSearchInput },
        });

        expect(urlUtils.getParameterByName).toHaveBeenCalledWith('regex');
        expect(storeUtils.setDataToLS).toHaveBeenCalledWith(LS_REGEX_HANDLE, true);
        expect(findRegularExpressionToggle().props('selected')).toBe(true);
      });

      it('regexEnabled state stays false if `regex=true` is not present in query params', () => {
        jest.spyOn(urlUtils, 'getParameterByName').mockReturnValue(undefined);

        createComponent({
          initialState: { query: { search: 'test' }, searchType: 'zoekt' },
          stubs: { GlobalSearchInput },
        });

        expect(urlUtils.getParameterByName).toHaveBeenCalledWith('regex');
        expect(storeUtils.setDataToLS).toHaveBeenCalledWith(LS_REGEX_HANDLE, false);
        expect(findRegularExpressionToggle().props('selected')).toBe(false);
      });
    });
  });
});
