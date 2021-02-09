import Vuex from 'vuex';
import { createLocalVue, mount } from '@vue/test-utils';
import { GlTabs, GlTab, GlBadge } from '@gitlab/ui';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { MOCK_QUERY, MOCK_SCOPE_TABS } from 'jest/search/mock_data';
import ScopeTabs from '~/search/topbar/components/scope_tabs.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ScopeTabs', () => {
  let wrapper;

  const actionSpies = {
    fetchSearchCounts: jest.fn(),
    setQuery: jest.fn(),
    resetQuery: jest.fn(),
  };

  const defaultProps = {
    scopeTabs: ['issues', 'merge_requests', 'milestones'],
    count: '20',
  };

  const createComponent = (props = {}, initialState = {}) => {
    const store = new Vuex.Store({
      state: {
        query: {
          ...MOCK_QUERY,
          search: 'test',
        },
        ...initialState,
      },
      actions: actionSpies,
    });

    wrapper = extendedWrapper(
      mount(ScopeTabs, {
        localVue,
        store,
        propsData: {
          ...defaultProps,
          ...props,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findScopeTabs = () => wrapper.find(GlTabs);
  const findTabs = () => wrapper.findAll(GlTab);
  const findBadges = () => wrapper.findAll(GlBadge);
  const findTabsTitle = () =>
    wrapper.findAll('[data-testid="tab-title"]').wrappers.map((w) => w.text());
  const findBadgesTitle = () => findBadges().wrappers.map((w) => w.text());
  const findBadgeByScope = (scope) => wrapper.findByTestId(`badge-${scope}`);
  const findTabByScope = (scope) => wrapper.findByTestId(`tab-${scope}`);

  describe('template', () => {
    beforeEach(() => {
      createComponent({}, { inflatedScopeTabs: MOCK_SCOPE_TABS });
    });

    it('always renders Scope Tabs', () => {
      expect(findScopeTabs().exists()).toBe(true);
    });

    describe('findTabs', () => {
      it('renders a tab for each scope', () => {
        expect(findTabs()).toHaveLength(defaultProps.scopeTabs.length);
        expect(findTabsTitle()).toStrictEqual([
          'Issues',
          'Titles and Descriptions',
          'Merge requests',
        ]);
      });
    });

    describe('findBadges', () => {
      it('renders a badge for each scope', () => {
        expect(findBadges()).toHaveLength(defaultProps.scopeTabs.length);
        expect(findBadgesTitle()).toStrictEqual(['15', '5', '1']);
      });

      it('sets the variant to neutral for active tab only', () => {
        expect(findBadgeByScope('issues').classes()).toContain('badge-neutral');
        expect(findBadgeByScope('snippet_titles').classes()).toContain('badge-muted');
        expect(findBadgeByScope('merge_requests').classes()).toContain('badge-muted');
      });
    });
  });

  describe('methods', () => {
    beforeEach(() => {
      createComponent({}, { inflatedScopeTabs: MOCK_SCOPE_TABS });

      findTabByScope('snippet_titles').vm.$emit('click');
    });

    describe('handleTabChange', () => {
      it('calls setQuery with scope, applies any search params from ALL_SCOPE_TABS, and sends nulls for page, state, confidential, and nav_source', () => {
        expect(actionSpies.setQuery).toHaveBeenCalledWith(expect.any(Object), {
          key: 'scope',
          value: 'snippet_titles',
        });
      });

      it('calls resetQuery and sends true for snippet_titles tab', () => {
        expect(actionSpies.resetQuery).toHaveBeenCalledWith(expect.any(Object), true);
      });

      it('calls resetQuery and does not send true for other tabs', () => {
        findTabByScope('issues').vm.$emit('click');
        expect(actionSpies.resetQuery).toHaveBeenCalledWith(expect.any(Object), false);
      });
    });
  });
});
