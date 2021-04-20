import { Server, Model, RestSerializer } from 'miragejs';
import setupRoutes from 'ee_else_ce_test_helpers/mock_server/routes';
import {
  getProject,
  getEmptyProject,
  getBranch,
  getMergeRequests,
  getMergeRequestWithChanges,
  getMergeRequestVersions,
  getRepositoryFiles,
  getBlobReadme,
  getBlobImage,
  getBlobZip,
} from 'test_helpers/fixtures';

export const createMockServerOptions = () => ({
  models: {
    project: Model,
    branch: Model,
    mergeRequest: Model,
    mergeRequestChange: Model,
    mergeRequestVersion: Model,
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
      files: getRepositoryFiles().map((path) => ({ path })),
      projects: [getProject(), getEmptyProject()],
      branches: [getBranch()],
      mergeRequests: getMergeRequests(),
      mergeRequestChanges: [getMergeRequestWithChanges()],
      mergeRequestVersions: getMergeRequestVersions(),
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
