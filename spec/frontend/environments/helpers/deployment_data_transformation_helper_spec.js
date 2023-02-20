import {
  getAuthorFromCommit,
  getCommitFromDeploymentNode,
  convertToDeploymentTableRow,
} from '~/environments/helpers/deployment_data_transformation_helper';

describe('deployment_data_transformation_helper', () => {
  const commitWithAuthor = {
    id: 'gid://gitlab/CommitPresenter/0cb48dd5deddb7632fd7c3defb16075fc6c3ca74',
    shortId: '0cb48dd5',
    message: 'Update .gitlab-ci.yml file',
    webUrl:
      'http://gdk.test:3000/gitlab-org/pipelinestest/-/commit/0cb48dd5deddb7632fd7c3defb16075fc6c3ca74',
    authorGravatar:
      'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
    authorName: 'Administrator',
    authorEmail: 'admin@example.com',
    author: {
      id: 'gid://gitlab/User/1',
      name: 'Administrator',
      avatarUrl: '/uploads/-/system/user/avatar/1/avatar.png',
      webUrl: 'http://gdk.test:3000/root',
    },
  };

  const commitWithoutAuthor = {
    id: 'gid://gitlab/CommitPresenter/02274a949a88c9aef68a29685d99bd9a661a7f9b',
    shortId: '02274a94',
    message: 'Commit message',
    webUrl:
      'http://gdk.test:3000/gitlab-org/pipelinestest/-/commit/02274a949a88c9aef68a29685d99bd9a661a7f9b',
    authorGravatar:
      'https://www.gravatar.com/avatar/91811aee1dec1b2655fa56f894e9e7c9?s=80&d=identicon',
    authorName: 'Andrei Zubov',
    authorEmail: 'azubov@gitlab.com',
    author: null,
  };

  const deploymentNode = {
    id: 'gid://gitlab/Deployment/76',
    iid: '31',
    status: 'SUCCESS',
    createdAt: '2022-10-17T07:44:17Z',
    ref: 'main',
    tag: false,
    job: {
      name: 'deploy-prod',
      refName: 'main',
      id: 'gid://gitlab/Ci::Build/860',
      webPath: '/gitlab-org/pipelinestest/-/jobs/860',
      deploymentPipeline: {
        jobs: {
          nodes: [
            {
              name: 'deploy-staging',
              playable: true,
              scheduledAt: '2023-01-17T11:02:41.369Z',
              webPath: 'https://gdk.test:3000/redeploy',
            },
            {
              name: 'deploy-production',
              playable: true,
              scheduledAt: '2023-01-17T11:02:41.369Z',
              webPath: 'https://gdk.test:3000/redeploy',
            },
          ],
        },
      },
    },
    commit: commitWithAuthor,
    triggerer: {
      id: 'gid://gitlab/User/1',
      webUrl: 'http://gdk.test:3000/root',
      name: 'Administrator',
      avatarUrl: '/uploads/-/system/user/avatar/1/avatar.png',
    },
    finishedAt: '2022-10-17T07:44:43Z',
  };

  const deploymentNodeWithNoJob = {
    ...deploymentNode,
    job: null,
    finishedAt: null,
  };

  const environment = {
    lastDeployment: {
      job: {
        name: 'deploy-production',
      },
    },
  };
  describe('getAuthorFromCommit', () => {
    it.each([commitWithAuthor, commitWithoutAuthor])('should be properly converted', (commit) => {
      expect(getAuthorFromCommit(commit)).toMatchSnapshot();
    });
  });

  describe('getCommitFromDeploymentNode', () => {
    it('should throw an error when commit field is missing', () => {
      const emptyDeploymentNode = {};

      expect(() => getCommitFromDeploymentNode(emptyDeploymentNode)).toThrow();
    });

    it('should get correclty formatted commit object', () => {
      expect(getCommitFromDeploymentNode(deploymentNode)).toMatchSnapshot();
    });
  });

  describe('convertToDeploymentTableRow', () => {
    const deploymentNodeWithEmptyJob = { ...deploymentNode, job: undefined };

    it.each([deploymentNode, deploymentNodeWithEmptyJob, deploymentNodeWithNoJob])(
      'should be converted to proper table row data',
      (node) => {
        expect(convertToDeploymentTableRow(node, environment)).toMatchSnapshot();
      },
    );
  });
});
