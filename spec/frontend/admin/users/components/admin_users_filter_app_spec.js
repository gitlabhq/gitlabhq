import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { GlFilteredSearch, GlFilteredSearchToken } from '@gitlab/ui';

import { s__ } from '~/locale';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import { visitUrl, getBaseURL } from '~/lib/utils/url_utility';
import AdminUsersFilterApp from '~/admin/users/components/admin_users_filter_app.vue';

const mockFilters = [
  {
    type: 'access_level',
    value: { data: 'admins', operator: '=' },
    id: 1,
  },
];

const accessLevelToken = {
  title: s__('AdminUsers|Access level'),
  type: 'access_level',
  token: GlFilteredSearchToken,
  operators: OPERATORS_IS,
  unique: true,
  options: [
    { value: 'admins', title: s__('AdminUsers|Administrator') },
    { value: 'external', title: s__('AdminUsers|External') },
  ],
};

jest.mock('~/lib/utils/url_utility', () => {
  return {
    ...jest.requireActual('~/lib/utils/url_utility'),
    visitUrl: jest.fn(),
  };
});

describe('AdminUsersFilterApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(AdminUsersFilterApp);
  };

  const findFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);
  const findAvailableTokens = () => findFilteredSearch().props('availableTokens');

  describe('Mounts GlFilteredSearch with corresponding  filters', () => {
    it.each`
      filter
      ${'admins'}
      ${'two_factor_enabled'}
      ${'two_factor_disabled'}
      ${'external'}
      ${'blocked'}
      ${'banned'}
      ${'blocked_pending_approval'}
      ${'deactivated'}
      ${'wop'}
      ${'trusted'}
    `(`includes token with $filter as option`, ({ filter }) => {
      createComponent();
      const availableTokens = findAvailableTokens();
      const tokenExists = availableTokens.find((token) => {
        return token.options?.find((option) => {
          return option.value === filter;
        });
      });

      expect(Boolean(tokenExists)).toBe(true);
    });

    /**
     * Currently BE support only one filter at the time
     * https://gitlab.com/gitlab-org/gitlab/-/issues/254377
     */
    it('filters available tokens to one that is chosen', async () => {
      createComponent();
      const filteredSearch = findFilteredSearch();
      filteredSearch.vm.$emit('input', mockFilters);
      await nextTick();
      expect(findAvailableTokens()).toEqual([accessLevelToken]);
    });
  });

  describe('URL search params', () => {
    afterEach(() => {
      window.history.pushState({}, null, '');
    });

    /**
     * Currently BE support only one filter at the time
     * https://gitlab.com/gitlab-org/gitlab/-/issues/254377
     */
    it('includes the only filter if query param `filter` equals one of available filters', () => {
      window.history.replaceState({}, '', '/?filter=admins');
      createComponent();
      expect(findAvailableTokens()).toEqual([accessLevelToken]);
    });

    // all possible filters are listed here app/assets/javascripts/admin/users/constants.js
    it('includes all available filters if query param `filter` is not acceptable filter', () => {
      window.history.replaceState({}, '', '/?filter=filter-that-does-not-exist');
      createComponent();

      // by default we have 3 filters [admin, 2da, state]
      expect(findAvailableTokens().length).toEqual(3);
    });

    it('triggers location changes having emitted `submit` event', async () => {
      createComponent();
      const filteredSearch = findFilteredSearch();
      filteredSearch.vm.$emit('submit', mockFilters);
      await nextTick();
      expect(visitUrl).toHaveBeenCalledWith(`${getBaseURL()}/?filter=admins`);
    });

    it('Removes all query param except filter if filter has been changed', async () => {
      window.history.replaceState({}, '', '/?page=2&filter=filter-that-does-not-exist');
      createComponent();
      const filteredSearch = findFilteredSearch();
      filteredSearch.vm.$emit('submit', mockFilters);
      await nextTick();
      expect(visitUrl).toHaveBeenCalledWith(`${getBaseURL()}/?filter=admins`);
    });

    it('adds `search_query` if raw text filter was submitted', async () => {
      createComponent();
      const filteredSearch = findFilteredSearch();
      filteredSearch.vm.$emit('submit', ['administrator']);
      await nextTick();
      expect(visitUrl).toHaveBeenCalledWith(`${getBaseURL()}/?search_query=administrator`);
    });
  });
});
