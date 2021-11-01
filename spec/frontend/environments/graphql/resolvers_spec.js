import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { resolvers } from '~/environments/graphql/resolvers';
import { TEST_HOST } from 'helpers/test_constants';
import { environmentsApp, resolvedEnvironmentsApp, folder, resolvedFolder } from './mock_data';

const ENDPOINT = `${TEST_HOST}/environments`;

describe('~/frontend/environments/graphql/resolvers', () => {
  let mockResolvers;
  let mock;

  beforeEach(() => {
    mockResolvers = resolvers(ENDPOINT);
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.reset();
  });

  describe('environmentApp', () => {
    it('should fetch environments and map them to frontend data', async () => {
      mock.onGet(ENDPOINT, { params: { nested: true } }).reply(200, environmentsApp);

      const app = await mockResolvers.Query.environmentApp();
      expect(app).toEqual(resolvedEnvironmentsApp);
    });
  });
  describe('folder', () => {
    it('should fetch the folder url passed to it', async () => {
      mock.onGet(ENDPOINT, { params: { per_page: 3 } }).reply(200, folder);

      const environmentFolder = await mockResolvers.Query.folder(null, {
        environment: { folderPath: ENDPOINT },
      });

      expect(environmentFolder).toEqual(resolvedFolder);
    });
  });
  describe('stopEnvironment', () => {
    it('should post to the stop environment path', async () => {
      mock.onPost(ENDPOINT).reply(200);

      await mockResolvers.Mutations.stopEnvironment(null, { environment: { stopPath: ENDPOINT } });

      expect(mock.history.post).toContainEqual(
        expect.objectContaining({ url: ENDPOINT, method: 'post' }),
      );
    });
  });
  describe('rollbackEnvironment', () => {
    it('should post to the retry environment path', async () => {
      mock.onPost(ENDPOINT).reply(200);

      await mockResolvers.Mutations.rollbackEnvironment(null, {
        environment: { retryUrl: ENDPOINT },
      });

      expect(mock.history.post).toContainEqual(
        expect.objectContaining({ url: ENDPOINT, method: 'post' }),
      );
    });
  });
  describe('deleteEnvironment', () => {
    it('should DELETE to the delete environment path', async () => {
      mock.onDelete(ENDPOINT).reply(200);

      await mockResolvers.Mutations.deleteEnvironment(null, {
        environment: { deletePath: ENDPOINT },
      });

      expect(mock.history.delete).toContainEqual(
        expect.objectContaining({ url: ENDPOINT, method: 'delete' }),
      );
    });
  });
  describe('cancelAutoStop', () => {
    it('should post to the auto stop path', async () => {
      mock.onPost(ENDPOINT).reply(200);

      await mockResolvers.Mutations.cancelAutoStop(null, {
        environment: { autoStopPath: ENDPOINT },
      });

      expect(mock.history.post).toContainEqual(
        expect.objectContaining({ url: ENDPOINT, method: 'post' }),
      );
    });
  });
});
