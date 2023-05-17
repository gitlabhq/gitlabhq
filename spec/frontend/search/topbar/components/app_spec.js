import { GlSearchBoxByClick, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { MOCK_QUERY } from 'jest/search/mock_data';
import GlobalSearchTopbar from '~/search/topbar/components/app.vue';
import GroupFilter from '~/search/topbar/components/group_filter.vue';
import ProjectFilter from '~/search/topbar/components/project_filter.vue';
import MarkdownDrawer from '~/vue_shared/components/markdown_drawer/markdown_drawer.vue';
import { SYNTAX_OPTIONS_DOCUMENT } from '~/search/topbar/constants';

Vue.use(Vuex);

describe('GlobalSearchTopbar', () => {
  let wrapper;

  const actionSpies = {
    applyQuery: jest.fn(),
    setQuery: jest.fn(),
    preloadStoredFrequentItems: jest.fn(),
  };

  const createComponent = (initialState, props, stubs) => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
        ...initialState,
      },
      actions: actionSpies,
    });

    wrapper = shallowMount(GlobalSearchTopbar, {
      store,
      propsData: props,
      stubs,
    });
  };

  const findGlSearchBox = () => wrapper.findComponent(GlSearchBoxByClick);
  const findGroupFilter = () => wrapper.findComponent(GroupFilter);
  const findProjectFilter = () => wrapper.findComponent(ProjectFilter);
  const findSyntaxOptionButton = () => wrapper.findComponent(GlButton);
  const findSyntaxOptionDrawer = () => wrapper.findComponent(MarkdownDrawer);

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

    describe('syntax option feature', () => {
      describe('template', () => {
        beforeEach(() => {
          createComponent(
            { query: { repository_ref: '' } },
            { elasticsearchEnabled: true, defaultBranchName: '' },
          );
        });

        it('renders button correctly', () => {
          expect(findSyntaxOptionButton().exists()).toBe(true);
        });

        it('renders drawer correctly', () => {
          expect(findSyntaxOptionDrawer().exists()).toBe(true);
          expect(findSyntaxOptionDrawer().attributes('documentpath')).toBe(SYNTAX_OPTIONS_DOCUMENT);
        });

        it('dispatched correct click action', () => {
          const draweToggleSpy = jest.fn();
          wrapper.vm.$refs.markdownDrawer.toggleDrawer = draweToggleSpy;

          findSyntaxOptionButton().vm.$emit('click');
          expect(draweToggleSpy).toHaveBeenCalled();
        });
      });

      describe.each`
        query                                      | propsData                                                       | hasSyntaxOptions
        ${null}                                    | ${{ elasticsearchEnabled: false, defaultBranchName: '' }}       | ${false}
        ${{ query: { repository_ref: '' } }}       | ${{ elasticsearchEnabled: false, defaultBranchName: '' }}       | ${false}
        ${{ query: { repository_ref: 'master' } }} | ${{ elasticsearchEnabled: false, defaultBranchName: 'master' }} | ${false}
        ${{ query: { repository_ref: 'master' } }} | ${{ elasticsearchEnabled: true, defaultBranchName: '' }}        | ${false}
        ${{ query: { repository_ref: '' } }}       | ${{ elasticsearchEnabled: true, defaultBranchName: 'master' }}  | ${true}
        ${{ query: { repository_ref: '' } }}       | ${{ elasticsearchEnabled: true, defaultBranchName: '' }}        | ${true}
        ${{ query: { repository_ref: 'master' } }} | ${{ elasticsearchEnabled: true, defaultBranchName: 'master' }}  | ${true}
      `(
        'renders the syntax option based on component state',
        ({ query, propsData, hasSyntaxOptions }) => {
          beforeEach(() => {
            createComponent(query, { ...propsData });
          });

          it(`does${
            hasSyntaxOptions ? '' : ' not'
          } have syntax option button when repository_ref: '${
            query?.query?.repository_ref
          }', elasticsearchEnabled: ${propsData.elasticsearchEnabled}, defaultBranchName: '${
            propsData.defaultBranchName
          }'`, () => {
            expect(findSyntaxOptionButton().exists()).toBe(hasSyntaxOptions);
          });

          it(`does${
            hasSyntaxOptions ? '' : ' not'
          } have syntax option drawer when repository_ref: '${
            query?.query?.repository_ref
          }', elasticsearchEnabled: ${propsData.elasticsearchEnabled}, defaultBranchName: '${
            propsData.defaultBranchName
          }'`, () => {
            expect(findSyntaxOptionDrawer().exists()).toBe(hasSyntaxOptions);
          });
        },
      );
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
