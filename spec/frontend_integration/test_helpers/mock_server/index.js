import { Server, Model, RestSerializer } from 'miragejs';
import {
  getProject,
  getEmptyProject,
  getBranch,
  getMergeRequests,
  getRepositoryFiles,
  getBlobReadme,
  getBlobImage,
  getBlobZip,
} from 'test_helpers/fixtures';
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
      projects: [getProject(), getEmptyProject()],
      branches: [getBranch()],
      mergeRequests: getMergeRequests(),
      filesRaw: [
        {
          raw: getBlobReadme(),
          path: 'README.md',
        },
        {
          raw: getBlobZip(),
          path: 'Gemfile.zip',
        },
        {
          raw: getBlobImage(),
          path: 'files/images/logo-white.png',
        },
      ],
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
