import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import { stubComponent } from 'helpers/stub_component';
import GlobalSearchTopbar from '~/search/topbar/components/app.vue';
import MarkdownDrawer from '~/vue_shared/components/markdown_drawer/markdown_drawer.vue';
import SearchTypeIndicator from '~/search/topbar/components/search_type_indicator.vue';
import GlSearchBoxByType from '~/search/topbar/components/search_box_by_type.vue';
import { ENTER_KEY } from '~/lib/utils/keys';
import {
  SYNTAX_OPTIONS_ADVANCED_DOCUMENT,
  SYNTAX_OPTIONS_ZOEKT_DOCUMENT,
} from '~/search/topbar/constants';

Vue.use(Vuex);

jest.mock('~/search/store/utils', () => ({
  loadDataFromLS: jest.fn(() => true),
  LS_REGEX_HANDLE: jest.fn(() => 'test'),
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

  const createComponent = ({
    initialState = {},
    defaultBranchName = '',
    stubs = {},
    featureFlag = {},
  } = {}) => {
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
      propsData: { defaultBranchName },
      stubs,
      provide: {
        glFeatures: featureFlag,
      },
    });
  };

  const findGlSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findSyntaxOptionButton = () => wrapper.findComponent(GlButton);
  const findSyntaxOptionDrawer = () => wrapper.findComponent(MarkdownDrawer);
  const findSearchTypeIndicator = () => wrapper.findComponent(SearchTypeIndicator);
  const findRegulareExpressionToggle = () =>
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
      state                                                                                                                   | hasSyntaxOptions
      ${{ query: { repository_ref: '' }, searchType: 'basic', searchLevel: 'project', defaultBranchName: 'master' }}          | ${false}
      ${{ query: { repository_ref: 'v0.1' }, searchType: 'basic', searchLevel: 'project', defaultBranchName: '' }}            | ${false}
      ${{ query: { repository_ref: 'master' }, searchType: 'basic', searchLevel: 'project', defaultBranchName: 'master' }}    | ${false}
      ${{ query: { repository_ref: 'master' }, searchType: 'advanced', searchLevel: 'project', defaultBranchName: '' }}       | ${false}
      ${{ query: { repository_ref: '' }, searchType: 'advanced', searchLevel: 'project', defaultBranchName: 'master' }}       | ${true}
      ${{ query: { repository_ref: 'v0.1' }, searchType: 'advanced', searchLevel: 'project', defaultBranchName: '' }}         | ${false}
      ${{ query: { repository_ref: 'master' }, searchType: 'advanced', searchLevel: 'project', defaultBranchName: 'master' }} | ${true}
      ${{ query: { repository_ref: 'master' }, searchType: 'zoekt', searchLevel: 'project', defaultBranchName: 'master' }}    | ${true}
    `(
      `the syntax option based on component state`,
      ({ state, defaultBranchName, hasSyntaxOptions }) => {
        beforeEach(() => {
          createComponent({
            initialState: { ...state },
            defaultBranchName,
          });
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
    describe.each`
      FF                                    | scope       | searchType    | called
      ${{ zoektMultimatchFrontend: false }} | ${'blobs'}  | ${'zoekt'}    | ${true}
      ${{ zoektMultimatchFrontend: false }} | ${'issues'} | ${'advanced'} | ${true}
      ${{ zoektMultimatchFrontend: false }} | ${'blobs'}  | ${'advanced'} | ${true}
      ${{ zoektMultimatchFrontend: true }}  | ${'issues'} | ${'advanced'} | ${true}
      ${{ zoektMultimatchFrontend: true }}  | ${'issues'} | ${'advanced'} | ${true}
      ${{ zoektMultimatchFrontend: true }}  | ${'blobs'}  | ${'zoekt'}    | ${false}
    `('hitting enter inside search box', ({ FF, scope, searchType, called }) => {
      beforeEach(() => {
        getterSpies.currentScope = jest.fn(() => scope);
        createComponent({
          featureFlag: FF,
          initialState: { searchType },
        });
      });

      it(`calls applyQuery ${called ? '' : 'NOT '}`, async () => {
        await nextTick();
        findGlSearchBox().vm.$emit('keydown', new KeyboardEvent({ key: ENTER_KEY }));
        expect(actionSpies.applyQuery).toHaveBeenCalledTimes(called ? 1 : 0);
      });
    });

    describe.each`
      search    | reload
      ${''}     | ${0}
      ${'test'} | ${1}
    `('clicking regular expression button', ({ search, reload }) => {
      beforeEach(() => {
        createComponent({
          initialState: { query: { search }, searchType: 'zoekt' },
          stubs: { GlSearchBoxByType },
        });
      });

      it(`calls setQuery and ${!reload ? 'NOT ' : ''}applyQuery if there is a search term`, () => {
        findRegulareExpressionToggle().vm.$emit('click');
        expect(actionSpies.setQuery).toHaveBeenCalled();
        expect(actionSpies.applyQuery).toHaveBeenCalledTimes(reload);
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
});
