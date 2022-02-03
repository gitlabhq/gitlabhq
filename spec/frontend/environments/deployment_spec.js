import { GlCollapse } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { useFakeDate } from 'helpers/fake_date';
import { stubTransition } from 'helpers/stub_transition';
import { formatDate } from '~/lib/utils/datetime_utility';
import { __, s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import Deployment from '~/environments/components/deployment.vue';
import Commit from '~/environments/components/commit.vue';
import DeploymentStatusBadge from '~/environments/components/deployment_status_badge.vue';
import { resolvedEnvironment } from './graphql/mock_data';

describe('~/environments/components/deployment.vue', () => {
  useFakeDate(2022, 0, 8, 16);

  let deployment;
  let wrapper;

  beforeEach(() => {
    deployment = resolvedEnvironment.lastDeployment;
  });

  const createWrapper = ({ propsData = {} } = {}) =>
    mountExtended(Deployment, {
      propsData: {
        deployment,
        ...propsData,
      },
      stubs: { transition: stubTransition() },
    });

  afterEach(() => {
    wrapper?.destroy();
  });

  describe('status', () => {
    it('should pass the deployable status to the badge', () => {
      wrapper = createWrapper();
      expect(wrapper.findComponent(DeploymentStatusBadge).props('status')).toBe(deployment.status);
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
        const sha = wrapper.findByTitle(__('Commit SHA'));

        expect(sha.exists()).toBe(true);
        expect(sha.text()).toBe(deployment.commit.shortId);
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

  describe('created at time', () => {
    describe('is present', () => {
      it('shows the timestamp the deployment was deployed at', () => {
        wrapper = createWrapper();
        const date = wrapper.findByTitle(formatDate(deployment.createdAt));

        expect(date.text()).toBe('1 day ago');
      });
    });
    describe('is not present', () => {
      it('does not show the timestamp', () => {
        wrapper = createWrapper({ propsData: { deployment: { createdAt: null } } });
        const date = wrapper.findByTitle(formatDate(deployment.createdAt));

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

  describe('collapse', () => {
    let collapse;
    let button;

    beforeEach(() => {
      wrapper = createWrapper();
      collapse = wrapper.findComponent(GlCollapse);
      button = wrapper.findComponent({ ref: 'details-toggle' });
    });

    it('is collapsed by default', () => {
      expect(collapse.attributes('visible')).toBeUndefined();
      expect(button.props('icon')).toBe('expand-down');
      expect(button.text()).toBe(__('Show details'));
    });

    it('opens on click', async () => {
      await button.trigger('click');

      expect(button.text()).toBe(__('Hide details'));
      expect(button.props('icon')).toBe('expand-up');
      expect(collapse.attributes('visible')).toBe('visible');
    });
  });
});
