import { GlFilteredSearch, GlKeysetPagination, GlSorting } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { setUrlParams, updateHistory } from '~/lib/utils/url_utility';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import PersonalAccessTokensApp from '~/personal_access_tokens/components/app.vue';
import PersonalAccessTokensTable from '~/personal_access_tokens/components/personal_access_tokens_table.vue';
import PersonalAccessTokenDrawer from '~/personal_access_tokens/components/personal_access_token_drawer.vue';
import CreatePersonalAccessTokenDropdown from '~/personal_access_tokens/components/create_personal_access_token_dropdown.vue';
import PersonalAccessTokenStatistics from '~/personal_access_tokens/components/personal_access_token_statistics.vue';
import PersonalAccessTokenActions from '~/personal_access_tokens/components/personal_access_token_actions.vue';
import RotatedPersonalAccessToken from '~/personal_access_tokens/components/rotated_personal_access_token.vue';
import getUserPersonalAccessTokens from '~/personal_access_tokens/graphql/get_user_personal_access_tokens.query.graphql';
import { DEFAULT_SORT, PAGE_SIZE } from '~/personal_access_tokens/constants';
import { mockTokens, mockPageInfo, mockQueryResponse } from '../mock_data';

jest.mock('~/alert');

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  setUrlParams: jest.fn(() => '/-/personal_access_tokens'),
  updateHistory: jest.fn(),
}));

Vue.use(VueApollo);

describe('PersonalAccessTokensApp', () => {
  let wrapper;
  let mockApollo;

  const mockQueryHandler = jest.fn().mockResolvedValue(mockQueryResponse);

  const createComponent = ({ queryHandler = mockQueryHandler } = {}) => {
    mockApollo = createMockApollo([[getUserPersonalAccessTokens, queryHandler]]);

    window.gon = { current_user_id: 123 };

    wrapper = shallowMountExtended(PersonalAccessTokensApp, {
      apolloProvider: mockApollo,
      stubs: {
        CrudComponent,
      },
    });
  };

  const findFilteredSearch = () => wrapper.findComponent(GlFilteredSearch);
  const findSorting = () => wrapper.findComponent(GlSorting);
  const findTable = () => wrapper.findComponent(PersonalAccessTokensTable);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findCreateDropdown = () => wrapper.findComponent(CreatePersonalAccessTokenDropdown);
  const findDrawer = () => wrapper.findComponent(PersonalAccessTokenDrawer);
  const findStatistics = () => wrapper.findComponent(PersonalAccessTokenStatistics);
  const findActions = () => wrapper.findComponent(PersonalAccessTokenActions);
  const findRotatedToken = () => wrapper.findComponent(RotatedPersonalAccessToken);

  beforeEach(() => {
    createComponent();
  });

  it('renders the filtered search component', () => {
    expect(findFilteredSearch().exists()).toBe(true);
    expect(findFilteredSearch().props('availableTokens')).toBeDefined();
  });

  it('renders the sorting component', () => {
    expect(findSorting().exists()).toBe(true);
    expect(findSorting().props()).toMatchObject({
      isAscending: DEFAULT_SORT.isAsc,
      sortBy: DEFAULT_SORT.value,
    });
  });

  it('renders the create dropdown', () => {
    expect(findCreateDropdown().exists()).toBe(true);
  });

  it('renders the table component', () => {
    expect(findTable().exists()).toBe(true);
  });

  describe('GraphQL query', () => {
    it('fetches tokens on mount', async () => {
      expect(findTable().props('loading')).toBe(true);

      await waitForPromises();

      expect(mockQueryHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/User/123',
        sort: 'EXPIRES_ASC',
        state: 'ACTIVE',
        first: PAGE_SIZE,
        after: null,
        last: null,
        before: null,
      });

      expect(setUrlParams).toHaveBeenNthCalledWith(
        1,
        { sort: 'expires_asc', state: 'active' },
        { url: 'http://test.host/', clearParams: true, decodeParams: true },
      );
      expect(updateHistory).toHaveBeenCalled();
    });

    it('passes tokens to the table', async () => {
      await waitForPromises();

      expect(findTable().props('loading')).toBe(false);
      expect(findTable().props('tokens')).toEqual(mockTokens);
    });

    it('shows alert on error', async () => {
      const errorHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));
      createComponent({ queryHandler: errorHandler });
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while fetching the tokens.',
        variant: 'danger',
      });
    });
  });

  describe('filtering', () => {
    it('refetches tokens when filter is cleared', async () => {
      findFilteredSearch().vm.$emit('clear');
      await nextTick();

      expect(mockQueryHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/User/123',
        sort: 'EXPIRES_ASC',
        first: PAGE_SIZE,
        after: null,
        last: null,
        before: null,
      });

      expect(setUrlParams).toHaveBeenNthCalledWith(2, { sort: 'expires_asc' }, expect.anything());
    });

    it('refetches when date field with less than operator is set', async () => {
      findFilteredSearch().vm.$emit('input', [
        { type: 'expires', value: { data: '2026-01-20', operator: '<' } },
        { type: 'created', value: { data: '2026-01-20', operator: '<' } },
        { type: 'lastUsed', value: { data: '2026-01-20', operator: '<' } },
      ]);

      findFilteredSearch().vm.$emit('submit');

      await nextTick();

      expect(mockQueryHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/User/123',
        sort: 'EXPIRES_ASC',
        first: PAGE_SIZE,
        after: null,
        last: null,
        before: null,
        expiresBefore: '2026-01-20',
        createdBefore: '2026-01-20',
        lastUsedBefore: '2026-01-20',
      });

      expect(setUrlParams).toHaveBeenNthCalledWith(
        2,
        {
          sort: 'expires_asc',
          expires_before: '2026-01-20',
          created_before: '2026-01-20',
          last_used_before: '2026-01-20',
        },
        expect.anything(),
      );
    });

    it('refetches when date field with greater than or equal to operator is set', async () => {
      findFilteredSearch().vm.$emit('input', [
        { type: 'expires', value: { data: '2026-01-20', operator: '≥' } },
        { type: 'created', value: { data: '2026-01-20', operator: '≥' } },
        { type: 'lastUsed', value: { data: '2026-01-20', operator: '≥' } },
      ]);

      findFilteredSearch().vm.$emit('submit');

      await nextTick();

      expect(mockQueryHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/User/123',
        sort: 'EXPIRES_ASC',
        first: PAGE_SIZE,
        after: null,
        last: null,
        before: null,
        expiresAfter: '2026-01-20',
        createdAfter: '2026-01-20',
        lastUsedAfter: '2026-01-20',
      });

      expect(setUrlParams).toHaveBeenNthCalledWith(
        2,
        {
          sort: 'expires_asc',
          expires_after: '2026-01-20',
          created_after: '2026-01-20',
          last_used_after: '2026-01-20',
        },
        expect.anything(),
      );
    });

    it('refetches when when search term is set', async () => {
      findFilteredSearch().vm.$emit('input', [
        { type: 'filtered-search-term', value: { data: 'token name' } },
      ]);

      findFilteredSearch().vm.$emit('submit');

      await nextTick();

      expect(mockQueryHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/User/123',
        sort: 'EXPIRES_ASC',
        first: PAGE_SIZE,
        after: null,
        last: null,
        before: null,
        search: 'token name',
      });

      expect(setUrlParams).toHaveBeenNthCalledWith(
        2,
        { sort: 'expires_asc', search: 'token name' },
        expect.anything(),
      );
    });

    it('refetches when filter is submitted', async () => {
      findFilteredSearch().vm.$emit('input', [
        { type: 'state', value: { data: 'INACTIVE' } },
        { type: 'revoked', value: { data: true } },
      ]);

      findFilteredSearch().vm.$emit('submit');

      await nextTick();

      expect(mockQueryHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/User/123',
        sort: 'EXPIRES_ASC',
        state: 'INACTIVE',
        revoked: true,
        first: PAGE_SIZE,
        after: null,
        last: null,
        before: null,
      });

      expect(setUrlParams).toHaveBeenNthCalledWith(
        2,
        { sort: 'expires_asc', state: 'inactive', revoked: 'true' },
        expect.anything(),
      );
    });

    it('does not refetch if submit button is not clicked', async () => {
      await waitForPromises();
      mockQueryHandler.mockClear();

      findFilteredSearch().vm.$emit('input', [
        { type: 'state', value: { data: 'INACTIVE' } },
        { type: 'revoked', value: { data: true } },
      ]);

      await nextTick();

      expect(mockQueryHandler).not.toHaveBeenCalled();
    });
  });

  describe('sorting', () => {
    it('updates sort value when changed', async () => {
      await waitForPromises();
      await findSorting().vm.$emit('sortByChange', 'name');

      expect(mockQueryHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/User/123',
        sort: 'NAME_ASC',
        state: 'ACTIVE',
        first: PAGE_SIZE,
        after: null,
        last: null,
        before: null,
      });

      expect(setUrlParams).toHaveBeenNthCalledWith(
        2,
        { sort: 'name_asc', state: 'active' },
        expect.anything(),
      );
    });

    it('updates sort direction when changed', async () => {
      await waitForPromises();
      await findSorting().vm.$emit('sortDirectionChange', false);

      expect(mockQueryHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/User/123',
        sort: 'EXPIRES_DESC',
        state: 'ACTIVE',
        first: PAGE_SIZE,
        after: null,
        last: null,
        before: null,
      });

      expect(setUrlParams).toHaveBeenNthCalledWith(
        2,
        { sort: 'expires_desc', state: 'active' },
        expect.anything(),
      );
    });
  });

  describe('pagination', () => {
    it('shows pagination when there are more pages', async () => {
      await waitForPromises();

      expect(findPagination().exists()).toBe(true);

      expect(findPagination().props()).toMatchObject({
        startCursor: mockPageInfo.startCursor,
        endCursor: mockPageInfo.endCursor,
        hasNextPage: mockPageInfo.hasNextPage,
        hasPreviousPage: mockPageInfo.hasPreviousPage,
      });
    });

    it('hides pagination when there are no more pages', async () => {
      const noPageInfoHandler = jest.fn().mockResolvedValue({
        data: {
          user: {
            id: 'gid://gitlab/User/123',
            personalAccessTokens: {
              nodes: mockTokens,
              pageInfo: { ...mockPageInfo, hasNextPage: false },
            },
          },
        },
      });

      createComponent({ queryHandler: noPageInfoHandler });
      await waitForPromises();

      expect(findPagination().exists()).toBe(false);
    });

    it('handles next page navigation', async () => {
      await waitForPromises();
      await findPagination().vm.$emit('next', 'cursor123');

      expect(mockQueryHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/User/123',
        sort: 'EXPIRES_ASC',
        state: 'ACTIVE',
        first: PAGE_SIZE,
        after: 'cursor123',
        last: null,
        before: null,
      });
    });

    it('handles previous page navigation', async () => {
      await waitForPromises();
      await findPagination().vm.$emit('prev', 'cursor456');

      expect(mockQueryHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/User/123',
        sort: 'EXPIRES_ASC',
        state: 'ACTIVE',
        first: null,
        after: null,
        last: PAGE_SIZE,
        before: 'cursor456',
      });
    });
  });

  describe('drawer integration', () => {
    it('opens drawer when table emits select event', async () => {
      await waitForPromises();

      findTable().vm.$emit('select', mockTokens[0]);
      await nextTick();

      expect(findDrawer().props('token')).toBe(mockTokens[0]);
    });

    it('closes drawer when drawer emits close event', async () => {
      await waitForPromises();

      findTable().vm.$emit('select', mockTokens[0]);
      await nextTick();

      findDrawer().vm.$emit('close');
      await nextTick();

      expect(findDrawer().props('token')).toBe(null);
    });
  });

  describe('statistics', () => {
    it('renders the statistics component', () => {
      expect(findStatistics().exists()).toBe(true);
    });

    it('handles statistics filter events', async () => {
      await findStatistics().vm.$emit('filter', [
        {
          type: 'state',
          value: {
            data: 'ACTIVE',
            operator: '=',
          },
        },
      ]);
      await nextTick();

      expect(mockQueryHandler).toHaveBeenCalledWith({
        id: 'gid://gitlab/User/123',
        sort: 'EXPIRES_ASC',
        state: 'ACTIVE',
        first: PAGE_SIZE,
        after: null,
        last: null,
        before: null,
      });
    });
  });

  describe('actions', () => {
    it('renders the actions component', () => {
      expect(findActions().exists()).toBe(true);
    });

    it('handles successful token rotation from drawer', async () => {
      await findDrawer().vm.$emit('rotate', mockTokens[0]);

      expect(findActions().props()).toMatchObject({
        token: mockTokens[0],
        action: 'rotate',
      });
    });

    it('handles successful token rotation from table', async () => {
      await findTable().vm.$emit('rotate', mockTokens[0]);

      expect(findActions().props()).toMatchObject({
        token: mockTokens[0],
        action: 'rotate',
      });
    });

    it('passes rotated token to `RotatedPersonalAccessToken` component', async () => {
      const tokenValue = 'xx';

      await findActions().vm.$emit('rotated', tokenValue);

      expect(findRotatedToken().props('value')).toBe(tokenValue);
    });

    it('clears the selected token on modal close', async () => {
      await findTable().vm.$emit('rotate', mockTokens[0]);

      await findActions().vm.$emit('close');

      expect(findActions().props()).toMatchObject({
        token: null,
        action: null,
      });
    });

    it('handles successful token revocation from drawer', async () => {
      await findDrawer().vm.$emit('revoke', mockTokens[1]);

      expect(findActions().props()).toMatchObject({
        token: mockTokens[1],
        action: 'revoke',
      });
    });

    it('handles successful token revocation from table', async () => {
      await findTable().vm.$emit('revoke', mockTokens[1]);

      expect(findActions().props()).toMatchObject({
        token: mockTokens[1],
        action: 'revoke',
      });
    });
  });
});
