import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { useFakeDate } from 'helpers/fake_date';
import { stubTransition } from 'helpers/stub_transition';
import { localeDateFormat } from '~/lib/utils/datetime_utility';
import { __, s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import Deployment from '~/environments/components/deployment.vue';
import Commit from '~/environments/components/commit.vue';
import DeploymentStatusLink from '~/environments/components/deployment_status_link.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import getDeploymentDetails from '~/environments/graphql/queries/deployment_details.query.graphql';
import { resolvedEnvironment, resolvedDeploymentDetails } from './graphql/mock_data';

describe('~/environments/components/deployment.vue', () => {
  Vue.use(VueApollo);
  useFakeDate(2022, 0, 8, 16);

  let deployment;
  let wrapper;

  beforeEach(() => {
    deployment = resolvedEnvironment.lastDeployment;
  });

  const createWrapper = ({ propsData = {}, options = {} } = {}) => {
    const mockApollo = createMockApollo([
      [getDeploymentDetails, jest.fn().mockResolvedValue(resolvedDeploymentDetails)],
    ]);

    return mountExtended(Deployment, {
      stubs: { transition: stubTransition() },
      propsData: {
        deployment,
        visible: true,
        ...propsData,
      },
      apolloProvider: mockApollo,
      provide: { projectPath: '/1' },
      ...options,
    });
  };

  afterEach(() => {
    wrapper?.destroy();
  });

  describe('status', () => {
    it('should pass the deployable status to the link', () => {
      wrapper = createWrapper();
      expect(wrapper.findComponent(DeploymentStatusLink).props()).toEqual({
        status: deployment.status,
        deploymentJob: deployment.deployable,
        deployment,
      });
    });
  });

  describe('latest', () => {
    it('should show a badge if the deployment is latest', () => {
      wrapper = createWrapper({ propsData: { latest: true } });

      const badge = wrapper.findByText(s__('Deployment|Latest Deployed'));

      expect(badge.exists()).toBe(true);
    });

    it('should not show a badge if the deployment is not latest', () => {
      wrapper = createWrapper();

      const badge = wrapper.findByText(s__('Deployment|Latest Deployed'));

      expect(badge.exists()).toBe(false);
    });
  });

  describe('iid', () => {
    const findIid = () => wrapper.findByTitle(s__('Deployment|Deployment ID'));
    const findDeploymentIcon = () => wrapper.findComponent({ ref: 'deployment-iid-icon' });

    describe('is present', () => {
      beforeEach(() => {
        wrapper = createWrapper();
      });

      it('should show the iid', () => {
        const iid = findIid();
        expect(iid.exists()).toBe(true);
      });

      it('should show an icon for the iid', () => {
        const deploymentIcon = findDeploymentIcon();
        expect(deploymentIcon.props('name')).toBe('deployments');
      });
    });

    describe('is not present', () => {
      beforeEach(() => {
        wrapper = createWrapper({ propsData: { deployment: { ...deployment, iid: '' } } });
      });

      it('should not show the iid', () => {
        const iid = findIid();
        expect(iid.exists()).toBe(false);
      });

      it('should not show an icon for the iid', () => {
        const deploymentIcon = findDeploymentIcon();
        expect(deploymentIcon.exists()).toBe(false);
      });
    });
  });

  describe('shortSha', () => {
    describe('is present', () => {
      beforeEach(() => {
        wrapper = createWrapper();
      });

      it('shows the short SHA for the commit of the deployment', () => {
        const sha = wrapper.findByRole('link', { name: __('Commit SHA') });

        expect(sha.exists()).toBe(true);
        expect(sha.text()).toBe(deployment.commit.shortId);
        expect(sha.attributes('href')).toBe(deployment.commit.commitPath);
      });

      it('shows the commit icon', () => {
        const icon = wrapper.findComponent({ ref: 'deployment-commit-icon' });
        expect(icon.props('name')).toBe('commit');
      });

      it('shows a copy button for the sha', () => {
        const button = wrapper.findComponent(ClipboardButton);
        expect(button.props()).toMatchObject({
          text: deployment.commit.shortId,
          title: __('Copy commit SHA'),
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
        const sha = wrapper.findByTestId('deployment-commit-sha');
        expect(sha.exists()).toBe(false);
      });
    });
  });
  describe('deployedAt', () => {
    describe('is present', () => {
      it('shows the timestamp the deployment was deployed at', () => {
        wrapper = createWrapper();
        const date = wrapper.findByTestId('deployment-timestamp');
        expect(date.text()).toBe('Deployed 1 day ago');
      });
    });
  });
  describe('created at time', () => {
    describe('is present and deploymentAt is null', () => {
      it('shows the timestamp the deployment was created at', () => {
        wrapper = createWrapper({ propsData: { deployment: { ...deployment, deployedAt: null } } });

        const date = wrapper.findByTestId('deployment-timestamp');
        expect(date.text()).toBe('Created 1 day ago');
      });
    });
    describe('is not present', () => {
      it('does not show the timestamp', () => {
        wrapper = createWrapper({ propsData: { deployment: { ...deployment, createdAt: null } } });
        const date = wrapper.findByTitle(
          localeDateFormat.asDateTimeFull.format(deployment.createdAt),
        );

        expect(date.exists()).toBe(false);
      });
    });
  });

  describe('commit message', () => {
    describe('with commit', () => {
      beforeEach(() => {
        wrapper = createWrapper();
      });

      it('shows the commit component', () => {
        const commit = wrapper.findComponent(Commit);
        expect(commit.props('commit')).toBe(deployment.commit);
      });
    });

    describe('without a commit', () => {
      it('displays nothing', () => {
        const noCommit = {
          ...deployment,
          commit: null,
        };
        wrapper = createWrapper({ propsData: { deployment: noCommit } });

        const commit = wrapper.findComponent(Commit);
        expect(commit.exists()).toBe(false);
      });
    });
  });

  describe('details', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('shows information about the deployment', () => {
      const username = wrapper.findByRole('link', { name: `@${deployment.user.username}` });

      expect(username.attributes('href')).toBe(deployment.user.path);
      const job = wrapper.findByRole('link', { name: deployment.deployable.name });
      expect(job.attributes('href')).toBe(deployment.deployable.buildPath);
      const apiBadge = wrapper.findByText(__('API'));
      expect(apiBadge.exists()).toBe(false);

      const branchLabel = wrapper.findByText(__('Branch'));
      expect(branchLabel.exists()).toBe(true);
      const tagLabel = wrapper.findByText(__('Tag'));
      expect(tagLabel.exists()).toBe(false);
      const ref = wrapper.findByRole('link', { name: deployment.ref.name });
      expect(ref.attributes('href')).toBe(deployment.ref.refPath);
    });

    it('shows information about tags related to the deployment', async () => {
      expect(wrapper.findByText(__('Tags')).exists()).toBe(true);
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);

      await waitForPromises();

      for (let i = 1; i < 6; i += 1) {
        const tagName = `testTag${i}`;
        const testTag = wrapper.findByText(tagName);
        expect(testTag.exists()).toBe(true);
        expect(testTag.attributes('href')).toBe(`tags/${tagName}`);
      }
      expect(wrapper.findByText(__('testTag6')).exists()).toBe(false);
      expect(wrapper.findByText(__('Tag')).exists()).toBe(false);
      // with more than 5 tags, show overflow marker
      expect(wrapper.findByText('...').exists()).toBe(true);
    });
  });

  describe('with tagged deployment', () => {
    beforeEach(() => {
      wrapper = createWrapper({ propsData: { deployment: { ...deployment, tag: true } } });
    });

    it('shows tags instead of branch', () => {
      const refLabel = wrapper.findByText(__('Tags'));
      expect(refLabel.exists()).toBe(true);

      const branchLabel = wrapper.findByText(__('Branch'));
      expect(branchLabel.exists()).toBe(false);
    });
  });

  describe('with API deployment', () => {
    beforeEach(() => {
      wrapper = createWrapper({ propsData: { deployment: { ...deployment, deployable: null } } });
    });

    it('shows API instead of a job name', () => {
      const apiBadge = wrapper.findByText(__('API'));
      expect(apiBadge.exists()).toBe(true);
    });
  });
  describe('without a job path', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        propsData: {
          deployment: { ...deployment, deployable: { name: deployment.deployable.name } },
        },
      });
    });

    it('shows a span instead of a link', () => {
      const job = wrapper.findByTitle(deployment.deployable.name);
      expect(job.attributes('href')).toBeUndefined();
    });
  });
});
