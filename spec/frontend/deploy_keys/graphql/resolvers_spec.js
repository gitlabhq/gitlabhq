import MockAdapter from 'axios-mock-adapter';
import { HTTP_STATUS_OK, HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';
import axios from '~/lib/utils/axios_utils';
import pageInfoQuery from '~/graphql_shared/client/page_info.query.graphql';
import currentPageQuery from '~/deploy_keys/graphql/queries/current_page.query.graphql';
import currentScopeQuery from '~/deploy_keys/graphql/queries/current_scope.query.graphql';
import confirmRemoveKeyQuery from '~/deploy_keys/graphql/queries/confirm_remove_key.query.graphql';
import { resolvers } from '~/deploy_keys/graphql/resolvers';

const ENDPOINTS = {
  enabledKeysEndpoint: '/enabled_keys',
  availableProjectKeysEndpoint: '/available_project_keys',
  availablePublicKeysEndpoint: '/available_public_keys',
};

describe('~/deploy_keys/graphql/resolvers', () => {
  let mockResolvers;
  let mock;
  let client;

  beforeEach(() => {
    mockResolvers = resolvers(ENDPOINTS);
    mock = new MockAdapter(axios);
    client = {
      writeQuery: jest.fn(),
      readQuery: jest.fn(),
      readFragment: jest.fn(),
      cache: { evict: jest.fn(), gc: jest.fn() },
    };
  });

  afterEach(() => {
    mock.reset();
  });

  describe('deployKeys', () => {
    const key = { id: 1, title: 'hello', edit_path: '/edit' };

    it.each(['enabledKeys', 'availableProjectKeys', 'availablePublicKeys'])(
      'should request the endpoint for the %s scope',
      async (scope) => {
        mock.onGet(ENDPOINTS[`${scope}Endpoint`]).reply(HTTP_STATUS_OK, { keys: [key] });

        const keys = await mockResolvers.Project.deployKeys(null, { scope, page: 1 }, { client });

        expect(keys).toEqual([
          { id: 1, title: 'hello', editPath: '/edit', __typename: 'LocalDeployKey' },
        ]);
      },
    );

    it('should default to enabled keys if a bad scope is given', async () => {
      const scope = 'bad';
      mock.onGet(ENDPOINTS.enabledKeysEndpoint).reply(HTTP_STATUS_OK, { keys: [key] });

      const keys = await mockResolvers.Project.deployKeys(null, { scope, page: 1 }, { client });

      expect(keys).toEqual([
        { id: 1, title: 'hello', editPath: '/edit', __typename: 'LocalDeployKey' },
      ]);
    });

    it('should request the given page', async () => {
      const scope = 'enabledKeys';
      const page = 2;
      mock
        .onGet(ENDPOINTS.enabledKeysEndpoint, { params: { page, per_page: 5 } })
        .reply(HTTP_STATUS_OK, { keys: [key] });

      const keys = await mockResolvers.Project.deployKeys(null, { scope, page }, { client });

      expect(keys).toEqual([
        { id: 1, title: 'hello', editPath: '/edit', __typename: 'LocalDeployKey' },
      ]);
    });

    it('should request the given search', async () => {
      const scope = 'enabledKeys';
      const search = { search: 'my-key', in: 'title' };
      const page = 1;

      mock
        .onGet(ENDPOINTS.enabledKeysEndpoint, { params: { ...search, page, per_page: 5 } })
        .reply(HTTP_STATUS_OK, { keys: [key] });

      const keys = await mockResolvers.Project.deployKeys(
        null,
        { scope, page, search },
        { client },
      );

      expect(keys).toEqual([
        { id: 1, title: 'hello', editPath: '/edit', __typename: 'LocalDeployKey' },
      ]);
    });

    it('should write pagination info to the cache', async () => {
      const scope = 'enabledKeys';
      const page = 1;

      mock.onGet(ENDPOINTS.enabledKeysEndpoint).reply(
        HTTP_STATUS_OK,
        { keys: [key] },
        {
          'x-next-page': '2',
          'x-page': '1',
          'X-Per-Page': '2',
          'X-Prev-Page': '',
          'X-TOTAL': '37',
          'X-Total-Pages': '5',
        },
      );

      await mockResolvers.Project.deployKeys(null, { scope, page }, { client });

      expect(client.writeQuery).toHaveBeenCalledWith({
        query: pageInfoQuery,
        variables: { input: { scope, page } },
        data: {
          pageInfo: {
            total: 37,
            perPage: 2,
            previousPage: NaN,
            totalPages: 5,
            nextPage: 2,
            page: 1,
            __typename: 'LocalPageInfo',
          },
        },
      });
    });

    it('should not write page info if the request fails', async () => {
      const scope = 'enabledKeys';
      const page = 1;

      mock.onGet(ENDPOINTS.enabledKeysEndpoint).reply(HTTP_STATUS_NOT_FOUND);

      try {
        await mockResolvers.Project.deployKeys(null, { scope, page }, { client });
      } catch {
        expect(client.writeQuery).not.toHaveBeenCalled();
      }
    });
  });

  describe('currentPage', () => {
    it('sets the current page', () => {
      const page = 5;
      mockResolvers.Mutation.currentPage(null, { page }, { client });

      expect(client.writeQuery).toHaveBeenCalledWith({
        query: currentPageQuery,
        data: { currentPage: page },
      });
    });
  });

  describe('currentScope', () => {
    let scope;

    beforeEach(() => {
      scope = 'enabledKeys';
      mockResolvers.Mutation.currentScope(null, { scope }, { client });
    });

    it('sets the current scope', () => {
      expect(client.writeQuery).toHaveBeenCalledWith({
        query: currentScopeQuery,
        data: { currentScope: scope },
      });
    });

    it('resets the page to 1', () => {
      expect(client.writeQuery).toHaveBeenCalledWith({
        query: currentPageQuery,
        data: { currentPage: 1 },
      });
    });

    it('throws failure on bad scope', () => {
      scope = 'bad scope';
      expect(() => mockResolvers.Mutation.currentScope(null, { scope }, { client })).toThrow(scope);
    });
  });

  describe('disableKey', () => {
    it('disables the key that is pending confirmation', async () => {
      const key = { id: 1, title: 'hello', disablePath: '/disable', __typename: 'LocalDeployKey' };
      client.readQuery.mockReturnValue({ deployKeyToRemove: key });
      client.readFragment.mockReturnValue(key);
      mock.onPut(key.disablePath).reply(HTTP_STATUS_OK);
      await mockResolvers.Mutation.disableKey(null, null, { client });

      expect(client.readQuery).toHaveBeenCalledWith({ query: confirmRemoveKeyQuery });
      expect(client.readFragment).toHaveBeenCalledWith(
        expect.objectContaining({ id: `LocalDeployKey:${key.id}` }),
      );
      expect(client.cache.evict).toHaveBeenCalledWith({ fieldName: 'deployKeyToRemove' });
      expect(client.cache.evict).toHaveBeenCalledWith({ id: `LocalDeployKey:${key.id}` });
      expect(client.cache.gc).toHaveBeenCalled();
    });

    it('does not remove the key from the cache on fail', async () => {
      const key = { id: 1, title: 'hello', disablePath: '/disable', __typename: 'LocalDeployKey' };
      client.readQuery.mockReturnValue({ deployKeyToRemove: key });
      client.readFragment.mockReturnValue(key);
      mock.onPut(key.disablePath).reply(HTTP_STATUS_NOT_FOUND);

      try {
        await mockResolvers.Mutation.disableKey(null, null, { client });
      } catch {
        expect(client.readQuery).toHaveBeenCalledWith({ query: confirmRemoveKeyQuery });
        expect(client.readFragment).toHaveBeenCalledWith(
          expect.objectContaining({ id: `LocalDeployKey:${key.id}` }),
        );
        expect(client.cache.evict).not.toHaveBeenCalled();
        expect(client.cache.gc).not.toHaveBeenCalled();
      }
    });
  });

  describe('enableKey', () => {
    it("calls the key's enable path", async () => {
      const key = { id: 1, title: 'hello', enablePath: '/enable', __typename: 'LocalDeployKey' };
      client.readQuery.mockReturnValue({ deployKeyToRemove: key });
      client.readFragment.mockReturnValue(key);
      mock.onPut(key.enablePath).reply(HTTP_STATUS_OK);
      await mockResolvers.Mutation.enableKey(null, key, { client });

      expect(client.readFragment).toHaveBeenCalledWith(
        expect.objectContaining({ id: `LocalDeployKey:${key.id}` }),
      );
      expect(client.cache.evict).toHaveBeenCalledWith({ id: `LocalDeployKey:${key.id}` });
      expect(client.cache.gc).toHaveBeenCalled();
    });

    it('does not remove the key from the cache on failure', async () => {
      const key = { id: 1, title: 'hello', enablePath: '/enable', __typename: 'LocalDeployKey' };
      client.readQuery.mockReturnValue({ deployKeyToRemove: key });
      client.readFragment.mockReturnValue(key);
      mock.onPut(key.enablePath).reply(HTTP_STATUS_NOT_FOUND);
      try {
        await mockResolvers.Mutation.enableKey(null, key, { client });
      } catch {
        expect(client.readFragment).toHaveBeenCalledWith(
          expect.objectContaining({ id: `LocalDeployKey:${key.id}` }),
        );
        expect(client.cache.evict).not.toHaveBeenCalled();
        expect(client.cache.gc).not.toHaveBeenCalled();
      }
    });
  });

  describe('confirmDisable', () => {
    it('sets the key to disable', () => {
      const key = { id: 1, title: 'hello', enablePath: '/enable', __typename: 'LocalDeployKey' };
      mockResolvers.Mutation.confirmDisable(null, key, { client });

      expect(client.writeQuery).toHaveBeenCalledWith({
        query: confirmRemoveKeyQuery,
        data: { deployKeyToRemove: { id: key.id, __type: 'LocalDeployKey' } },
      });
    });
    it('clears the value when null id is passed', () => {
      mockResolvers.Mutation.confirmDisable(null, { id: null }, { client });

      expect(client.writeQuery).toHaveBeenCalledWith({
        query: confirmRemoveKeyQuery,
        data: { deployKeyToRemove: null },
      });
    });
  });
});
