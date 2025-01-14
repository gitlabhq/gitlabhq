import { GlIcon, GlLink, GlTruncate, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import Deployment from '~/environments/components/deployment.vue';
import Commit from '~/environments/components/commit.vue';
import DeploymentStatusLink from '~/environments/components/deployment_status_link.vue';
import { resolvedEnvironment } from './graphql/mock_data';

describe('~/environments/components/deployment.vue', () => {
  let deployment;
  let wrapper;

  beforeEach(() => {
    deployment = resolvedEnvironment.lastDeployment;
  });

  const createWrapper = ({ propsData = {} } = {}) => {
    return shallowMountExtended(Deployment, {
      propsData: {
        deployment,
        ...propsData,
      },
      stubs: { GlTruncate, GlSprintf },
    });
  };

  const findStatusLink = () => wrapper.findComponent(DeploymentStatusLink);
  const findLatestBadge = () => wrapper.findByText('Latest Deployed');
  const findApprovalBadge = () => wrapper.findByText('Needs Approval');
  const findCommit = () => wrapper.findComponent(Commit);
  const findShortSha = () => wrapper.findByTestId('deployment-commit-sha');
  const findCopyButton = () => wrapper.findComponent(ClipboardButton);
  const findShortShaLink = () => findShortSha().findComponent(GlLink);
  const findShortShaIcon = () => findShortSha().findComponent(GlIcon);
  const findTag = () => wrapper.findByTestId('deployment-tag');
  const findTagLink = () => findTag().findComponent(GlLink);
  const findTagIcon = () => findTag().findComponent(GlIcon);
  const findTimestamp = () => wrapper.findByTestId('deployment-timestamp');
  const findTriggerer = () => wrapper.findByTestId('deployment-triggerer');
  const findUserLink = () => findTriggerer().findComponent(GlLink);

  describe('status', () => {
    it('should pass the deployable status to the link', () => {
      wrapper = createWrapper();
      expect(findStatusLink().props()).toEqual({
        status: deployment.status,
        deploymentJob: deployment.deployable,
        deployment,
      });
    });
  });

  describe('latest', () => {
    it('should show a badge if the deployment is latest', () => {
      wrapper = createWrapper({ propsData: { latest: true } });

      expect(findLatestBadge().exists()).toBe(true);
    });

    it('should not show a badge if the deployment is not latest', () => {
      wrapper = createWrapper();

      expect(findLatestBadge().exists()).toBe(false);
    });
  });

  describe('approval badge', () => {
    it('should show a badge if the deployment needs approval', () => {
      wrapper = createWrapper({
        propsData: { deployment: { ...deployment, pendingApprovalCount: 5 } },
      });

      expect(findApprovalBadge().exists()).toBe(true);
    });

    it('should not show a badge if the deployment does not need approval', () => {
      wrapper = createWrapper();

      expect(findApprovalBadge().exists()).toBe(false);
    });
  });

  describe('commit message', () => {
    describe('with commit', () => {
      beforeEach(() => {
        wrapper = createWrapper();
      });

      it('shows the commit component', () => {
        expect(findCommit().props('commit')).toBe(deployment.commit);
      });
    });

    describe('without a commit', () => {
      it('displays nothing', () => {
        const noCommit = {
          ...deployment,
          commit: null,
        };
        wrapper = createWrapper({ propsData: { deployment: noCommit } });

        expect(findCommit().exists()).toBe(false);
      });
    });
  });

  describe('shortSha', () => {
    describe('is present', () => {
      beforeEach(() => {
        wrapper = createWrapper();
      });

      it('shows the short SHA for the commit of the deployment', () => {
        expect(findShortShaLink().text()).toBe(deployment.commit.shortId);
        expect(findShortShaLink().attributes('href')).toBe(deployment.commit.commitPath);
      });

      it('shows the commit icon', () => {
        expect(findShortShaIcon().props('name')).toBe('commit');
      });

      it('shows a copy button for the sha', () => {
        expect(findCopyButton().props()).toMatchObject({
          text: deployment.commit.shortId,
          title: 'Copy commit SHA',
        });
      });
    });

    describe('is not present', () => {
      it('does not show the short SHA for the commit of the deployment', () => {
        wrapper = createWrapper({
          propsData: {
            deployment: {
              ...deployment,
              commit: null,
            },
          },
        });
        expect(findShortSha().exists()).toBe(false);
      });
    });
  });

  describe('tag', () => {
    describe('is present', () => {
      const ref = {
        name: 'v1.0.0',
        refPath: '/tags/v1.0.0',
      };
      beforeEach(() => {
        const deploymentWithTag = {
          ...deployment,
          tag: true,
          ref,
        };
        wrapper = createWrapper({
          propsData: {
            deployment: deploymentWithTag,
          },
        });
      });

      it('shows tag information', () => {
        expect(findTagLink().text()).toBe(ref.name);
        expect(findTagLink().attributes('href')).toBe(ref.refPath);
      });

      it('displays the tag icon', () => {
        expect(findTagIcon().props('name')).toBe('tag');
      });
    });

    describe('is not present', () => {
      it('does not show the tag', () => {
        wrapper = createWrapper();
        expect(findTag().exists()).toBe(false);
      });
    });
  });

  describe('triggered text', () => {
    it('shows the timestamp the deployment was created at if deployedAt is null', () => {
      wrapper = createWrapper({
        propsData: { deployment: { ...deployment, deployedAt: null } },
      });
      expect(findTimestamp().text()).toBe('January 7, 2022 at 3:46:27 PM GMT');
    });

    it('shows the timestamp the deployment was deployed at if deployedAt is present', () => {
      wrapper = createWrapper();
      expect(findTimestamp().text()).toBe('January 7, 2022 at 3:47:32 PM GMT');
    });

    describe('is not present', () => {
      it('does not show the timestamp', () => {
        wrapper = createWrapper({
          propsData: { deployment: { ...deployment, createdAt: null, deployedAt: null } },
        });

        expect(findTimestamp().exists()).toBe(false);
      });
    });
  });

  describe('deployment user', () => {
    describe('is present', () => {
      beforeEach(() => {
        wrapper = createWrapper();
      });

      it('shows triggerer information', () => {
        expect(findUserLink().text()).toBe('@root');
        expect(findUserLink().attributes('href')).toBe('/root');
      });
    });

    describe('is not present', () => {
      const deploymentWithoutUser = {
        ...deployment,
        user: null,
      };

      it('does not show the tag', () => {
        wrapper = createWrapper({
          propsData: {
            deployment: deploymentWithoutUser,
          },
        });
        expect(findTriggerer().exists()).toBe(false);
      });
    });
  });
});
