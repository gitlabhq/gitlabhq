import { SOLO_OWNED_ORGANIZATIONS_EMPTY } from '~/admin/users/constants';
import {
  initializeValuesFromQuery,
  getSoloOwnedOrganizations,
  generateUserPaths,
} from '~/admin/users/utils';
import { OPERATOR_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import {
  oneSoloOwnedOrganization,
  STANDARD_TOKEN_CONFIGS,
  FILTER_TOKEN_CONFIGS,
} from './mock_data';

jest.mock('~/admin/users', () => ({
  apolloClient: {
    query: jest.fn(),
  },
}));

const allFilterTokenOptions = FILTER_TOKEN_CONFIGS.flatMap(({ type, options }) =>
  options.map(({ value }) => ({ value, type })),
);

const setQuerystring = (params) => {
  window.history.replaceState({}, '', params);
};

describe('initializeValuesFromQuery', () => {
  it('parses `search_query` query parameter correctly', () => {
    setQuerystring('?search_query=dummy');

    expect(initializeValuesFromQuery(FILTER_TOKEN_CONFIGS, STANDARD_TOKEN_CONFIGS)).toMatchObject({
      tokenValues: ['dummy'],
      sort: undefined,
    });
  });

  it.each(allFilterTokenOptions)('parses `filter` query parameter `$value`', ({ value, type }) => {
    setQuerystring(`?search_query=dummy&filter=${value}`);

    expect(initializeValuesFromQuery(FILTER_TOKEN_CONFIGS, STANDARD_TOKEN_CONFIGS)).toMatchObject({
      tokenValues: [{ type, value: { data: value, operator: OPERATOR_IS } }, 'dummy'],
      sort: undefined,
    });
  });

  it('parses `sort` query parameter correctly', () => {
    setQuerystring('?sort=last_activity_on_asc');

    expect(initializeValuesFromQuery(FILTER_TOKEN_CONFIGS, STANDARD_TOKEN_CONFIGS)).toMatchObject({
      tokenValues: [],
      sort: 'last_activity_on_asc',
    });
  });

  it('ignores `filter` query parameter not found in the TOKEN options', () => {
    setQuerystring('?filter=unknown');

    expect(initializeValuesFromQuery(FILTER_TOKEN_CONFIGS, STANDARD_TOKEN_CONFIGS)).toMatchObject({
      tokenValues: [],
      sort: undefined,
    });
  });

  it('ignores other query parameters other than `filter` and `search_query` and `sort`', () => {
    setQuerystring('?other=value');

    expect(initializeValuesFromQuery(FILTER_TOKEN_CONFIGS, STANDARD_TOKEN_CONFIGS)).toMatchObject({
      tokenValues: [],
      sort: undefined,
    });
  });
});

describe('generateUserPaths', () => {
  it('replaces the `id` path segment with the given id', () => {
    const paths = {
      edit: '/admin/users/id/edit',
      delete: '/admin/users/id',
      deleteWithContributions: '/admin/users/id?hard_delete=true',
    };

    expect(generateUserPaths(paths, 'root')).toEqual({
      edit: '/admin/users/root/edit',
      delete: '/admin/users/root',
      deleteWithContributions: '/admin/users/root?hard_delete=true',
    });
  });

  it('does not replace `id` inside an organization slug', () => {
    const paths = {
      edit: '/o/rapid-corp/admin/users/id/edit',
    };

    expect(generateUserPaths(paths, 'root')).toEqual({
      edit: '/o/rapid-corp/admin/users/root/edit',
    });
  });

  it('replaces only the `/users/id` placeholder when a path segment is literally `id`', () => {
    const paths = {
      edit: '/o/id/admin/users/id/edit',
    };

    expect(generateUserPaths(paths, 'root')).toEqual({
      edit: '/o/id/admin/users/root/edit',
    });
  });
});

describe('getSoloOwnedOrganizations', () => {
  const apolloClient = {
    query: jest.fn(),
  };

  describe('when uiForOrganizations is disabled', () => {
    it('returns resolved promise with empty solo owned organizations', async () => {
      await expect(getSoloOwnedOrganizations(apolloClient, 1)).resolves.toEqual(
        SOLO_OWNED_ORGANIZATIONS_EMPTY,
      );
    });
  });

  describe('when uiForOrganizations is enabled', () => {
    beforeEach(() => {
      window.gon = {
        features: {
          uiForOrganizations: true,
        },
      };

      apolloClient.query.mockResolvedValueOnce({
        data: { user: { organizations: oneSoloOwnedOrganization } },
      });
    });

    afterEach(() => {
      window.gon = {};
    });

    it('calls API and returns result', async () => {
      await expect(getSoloOwnedOrganizations(apolloClient, 1)).resolves.toEqual(
        oneSoloOwnedOrganization,
      );
    });
  });
});
