import { Server, Model, RestSerializer } from 'miragejs';
import { getProject, getBranch, getMergeRequests, getRepositoryFiles } from 'test_helpers/fixtures';
import setupRoutes from './routes';

export const createMockServerOptions = () => ({
  models: {
    project: Model,
    branch: Model,
    mergeRequest: Model,
    file: Model,
    userPermission: Model,
  },
  serializers: {
    application: RestSerializer.extend({
      root: false,
    }),
  },
  seeds(schema) {
    schema.db.loadData({
      files: getRepositoryFiles().map(path => ({ path })),
      projects: [getProject()],
      branches: [getBranch()],
      mergeRequests: getMergeRequests(),
      userPermissions: [
        {
          createMergeRequestIn: true,
          readMergeRequest: true,
          pushCode: true,
        },
      ],
    });
  },
  routes() {
    this.namespace = '';
    this.urlPrefix = '/';

    setupRoutes(this);
  },
});

export const createMockServer = () => {
  const server = new Server(createMockServerOptions());

  return server;
};
