import { TOKEN_CONFIGS, SOLO_OWNED_ORGANIZATIONS_EMPTY } from '~/admin/users/constants';
import { initializeValuesFromQuery, getSoloOwnedOrganizations } from '~/admin/users/utils';
import { OPERATOR_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import { oneSoloOwnedOrganization } from './mock_data';

jest.mock('~/admin/users', () => ({
  apolloClient: {
    query: jest.fn(),
  },
}));

const allFilters = TOKEN_CONFIGS.flatMap(({ type, options }) =>
  options.map(({ value }) => ({ value, type })),
);

const setQuerystring = (params) => {
  window.history.replaceState({}, '', params);
};

describe('initializeValuesFromQuery', () => {
  it('parses `search_query` query parameter correctly', () => {
    setQuerystring('?search_query=dummy');

    expect(initializeValuesFromQuery()).toMatchObject({
      tokenValues: ['dummy'],
      sort: undefined,
    });
  });

  it.each(allFilters)('parses `filter` query parameter `$value`', ({ value, type }) => {
    setQuerystring(`?search_query=dummy&filter=${value}`);

    expect(initializeValuesFromQuery()).toMatchObject({
      tokenValues: [{ type, value: { data: value, operator: OPERATOR_IS } }, 'dummy'],
      sort: undefined,
    });
  });

  it('parses `sort` query parameter correctly', () => {
    setQuerystring('?sort=last_activity_on_asc');

    expect(initializeValuesFromQuery()).toMatchObject({
      tokenValues: [],
      sort: 'last_activity_on_asc',
    });
  });

  it('ignores `filter` query parameter not found in the TOKEN options', () => {
    setQuerystring('?filter=unknown');

    expect(initializeValuesFromQuery()).toMatchObject({
      tokenValues: [],
      sort: undefined,
    });
  });

  it('ignores other query parameters other than `filter` and `search_query` and `sort`', () => {
    setQuerystring('?other=value');

    expect(initializeValuesFromQuery()).toMatchObject({
      tokenValues: [],
      sort: undefined,
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
