import { GlFilteredSearchToken } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommitFilteredSearch from '~/projects/commits/components/commit_filtered_search.vue';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import {
  TOKEN_TYPE_AUTHOR,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TYPE_MESSAGE,
  TOKEN_TITLE_MESSAGE,
  OPERATORS_IS,
  OPERATOR_IS,
  TOKEN_TYPE_COMMITTED_AFTER,
  TOKEN_TYPE_COMMITTED_BEFORE,
  TOKEN_TITLE_COMMITTED_AFTER,
  TOKEN_TITLE_COMMITTED_BEFORE,
} from '~/vue_shared/components/filtered_search_bar/constants';
import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';
import DateToken from '~/vue_shared/components/filtered_search_bar/tokens/date_token.vue';

describe('CommitFilteredSearch', () => {
  let wrapper;

  const defaultProvide = {
    projectFullPath: 'gitlab-org/gitlab',
  };

  const createComponent = (provide = {}, props = {}) => {
    wrapper = shallowMountExtended(CommitFilteredSearch, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
      propsData: props,
    });
  };

  const findFilteredSearchBar = () => wrapper.findComponent(FilteredSearchBar);

  beforeEach(() => {
    createComponent();
  });

  describe('template', () => {
    it('renders FilteredSearchBar component', () => {
      expect(findFilteredSearchBar().exists()).toBe(true);
    });

    it('passes correct props to FilteredSearchBar', () => {
      const props = findFilteredSearchBar().props();

      expect(props).toMatchObject({
        namespace: 'gitlab-org/gitlab',
        tokens: [
          {
            type: TOKEN_TYPE_AUTHOR,
            title: TOKEN_TITLE_AUTHOR,
            icon: 'pencil',
            token: UserToken,
            dataType: 'user',
            valueField: 'name',
            defaultUsers: [],
            operators: OPERATORS_IS,
            fullPath: 'gitlab-org/gitlab',
            isProject: true,
            recentSuggestionsStorageKey: 'gitlab-org/gitlab-commits-recent-tokens-author',
            preloadedUsers: [],
            unique: true,
          },
          {
            type: TOKEN_TYPE_MESSAGE,
            title: TOKEN_TITLE_MESSAGE,
            icon: 'comment',
            token: GlFilteredSearchToken,
            operators: OPERATORS_IS,
            unique: true,
          },
          {
            type: TOKEN_TYPE_COMMITTED_AFTER,
            title: TOKEN_TITLE_COMMITTED_AFTER,
            icon: 'calendar',
            token: DateToken,
            operators: OPERATORS_IS,
            unique: true,
          },
          {
            type: TOKEN_TYPE_COMMITTED_BEFORE,
            title: TOKEN_TITLE_COMMITTED_BEFORE,
            icon: 'calendar',
            token: DateToken,
            operators: OPERATORS_IS,
            unique: true,
          },
        ],
        initialFilterValue: [],
        searchInputPlaceholder: 'Search or filter results...',
        recentSearchesStorageKey: 'commits',
        showFriendlyText: true,
        syncFilterAndSort: true,
        termsAsTokens: true,
      });
    });
  });

  describe('events', () => {
    it('emits filter event when FilteredSearchBar emits onFilter', () => {
      const filterTokens = [{ type: TOKEN_TYPE_AUTHOR, value: { data: 'author1' } }];

      findFilteredSearchBar().vm.$emit('onFilter', filterTokens);

      expect(wrapper.emitted('filter')).toEqual([[filterTokens]]);
    });

    it('emits filter event with message token when FilteredSearchBar emits onFilter', () => {
      const filterTokens = [{ type: TOKEN_TYPE_MESSAGE, value: { data: 'fix bug' } }];

      findFilteredSearchBar().vm.$emit('onFilter', filterTokens);

      expect(wrapper.emitted('filter')).toEqual([[filterTokens]]);
    });

    it('emits filter event with multiple tokens when FilteredSearchBar emits onFilter', () => {
      const filterTokens = [
        { type: TOKEN_TYPE_AUTHOR, value: { data: 'author1' } },
        { type: TOKEN_TYPE_MESSAGE, value: { data: 'fix bug' } },
      ];

      findFilteredSearchBar().vm.$emit('onFilter', filterTokens);

      expect(wrapper.emitted('filter')).toEqual([[filterTokens]]);
    });

    it('emits filter event with committed-after token when FilteredSearchBar emits onFilter', () => {
      const filterTokens = [{ type: TOKEN_TYPE_COMMITTED_AFTER, value: { data: '2025-01-01' } }];

      findFilteredSearchBar().vm.$emit('onFilter', filterTokens);

      expect(wrapper.emitted('filter')).toEqual([[filterTokens]]);
    });

    it('emits filter event with committed-before token when FilteredSearchBar emits onFilter', () => {
      const filterTokens = [{ type: TOKEN_TYPE_COMMITTED_BEFORE, value: { data: '2025-12-31' } }];

      findFilteredSearchBar().vm.$emit('onFilter', filterTokens);

      expect(wrapper.emitted('filter')).toEqual([[filterTokens]]);
    });

    it('emits filter event with date range tokens when FilteredSearchBar emits onFilter', () => {
      const filterTokens = [
        { type: TOKEN_TYPE_COMMITTED_AFTER, value: { data: '2025-01-01' } },
        { type: TOKEN_TYPE_COMMITTED_BEFORE, value: { data: '2025-12-31' } },
      ];

      findFilteredSearchBar().vm.$emit('onFilter', filterTokens);

      expect(wrapper.emitted('filter')).toEqual([[filterTokens]]);
    });
  });

  describe('with initial filter tokens', () => {
    it('initializes filterTokens from prop', () => {
      const initialTokens = [
        { type: TOKEN_TYPE_AUTHOR, value: { data: 'admin', operator: OPERATOR_IS } },
      ];

      createComponent({}, { initialFilterTokens: initialTokens });

      expect(findFilteredSearchBar().props('initialFilterValue')).toEqual(initialTokens);
    });

    it('initializes filterTokens with multiple tokens from prop', () => {
      const initialTokens = [
        { type: TOKEN_TYPE_AUTHOR, value: { data: 'admin', operator: OPERATOR_IS } },
        { type: TOKEN_TYPE_MESSAGE, value: { data: 'fix bug', operator: OPERATOR_IS } },
      ];

      createComponent({}, { initialFilterTokens: initialTokens });

      expect(findFilteredSearchBar().props('initialFilterValue')).toEqual(initialTokens);
    });

    it('initializes with empty array when no initialFilterTokens prop is provided', () => {
      createComponent();

      expect(findFilteredSearchBar().props('initialFilterValue')).toEqual([]);
    });

    it('updates filterTokens when initialFilterTokens prop changes', async () => {
      const initialTokens = [
        { type: TOKEN_TYPE_AUTHOR, value: { data: 'admin', operator: OPERATOR_IS } },
      ];

      createComponent({}, { initialFilterTokens: initialTokens });

      expect(findFilteredSearchBar().props('initialFilterValue')).toEqual(initialTokens);

      const newTokens = [
        { type: TOKEN_TYPE_MESSAGE, value: { data: 'refactor', operator: OPERATOR_IS } },
      ];

      await wrapper.setProps({ initialFilterTokens: newTokens });

      expect(findFilteredSearchBar().props('initialFilterValue')).toEqual(newTokens);
    });

    it('creates a copy of initialFilterTokens to avoid mutation', () => {
      const initialTokens = [
        { type: TOKEN_TYPE_AUTHOR, value: { data: 'admin', operator: OPERATOR_IS } },
      ];

      createComponent({}, { initialFilterTokens: initialTokens });

      expect(wrapper.vm.filterTokens).not.toBe(initialTokens);
      expect(wrapper.vm.filterTokens).toEqual(initialTokens);
    });
  });
});
