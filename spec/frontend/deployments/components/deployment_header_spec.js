import { GlSkeletonLoader } from '@gitlab/ui';
import mockDeploymentFixture from 'test_fixtures/graphql/deployments/graphql/queries/deployment.query.graphql.json';
import mockEnvironmentFixture from 'test_fixtures/graphql/deployments/graphql/queries/environment.query.graphql.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import DeploymentStatusLink from '~/environments/components/deployment_status_link.vue';
import DeploymentHeader from '~/deployments/components/deployment_header.vue';
import DeploymentCommit from '~/environments/components/commit.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

const {
  data: {
    project: { deployment },
  },
} = mockDeploymentFixture;
const {
  data: {
    project: { environment },
  },
} = mockEnvironmentFixture;

describe('~/deployments/components/deployment_header.vue', () => {
  let wrapper;

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(DeploymentHeader, {
      propsData: {
        deployment,
        environment,
        loading: false,
        ...propsData,
      },
    });
  };

  describe('loading', () => {
    it('shows a skeleton loader while loading', () => {
      createComponent({ propsData: { loading: true } });

      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
    });
  });

  describe('finished deployment', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows the deployment status link', () => {
      const link = wrapper.findComponent(DeploymentStatusLink);
      expect(link.props('status')).toBe(deployment.status.toLowerCase());
      expect(link.props('deploymentJob')).toEqual(deployment.job);
    });

    it('shows a link to the environment name', () => {
      const link = wrapper.findByRole('link', { name: environment.name });
      expect(link.attributes('href')).toBe(environment.path);
    });

    it('shows a link to the commit', () => {
      const link = wrapper.findByRole('link', { name: deployment.commit.shortId });
      expect(link.attributes('href')).toBe(deployment.commit.webPath);
    });

    it('has a clipboard button that copies the commit SHA', () => {
      const button = wrapper.findComponent(ClipboardButton);

      expect(button.props()).toMatchObject({
        text: deployment.commit.shortId,
        title: 'Copy commit SHA',
      });
    });

    it('shows when the deployment finished', () => {
      const timeago = wrapper.findComponent(TimeAgoTooltip);

      expect(timeago.text()).toBe(`Finished 6 months ago by @${deployment.triggerer.username}`);
    });

    it('shows the commit message for the deployment', () => {
      const commit = wrapper.findComponent(DeploymentCommit);

      expect(commit.props('commit')).toEqual(deployment.commit);
    });
  });

  describe('unfinished deployment', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          deployment: {
            ...deployment,
            status: 'running',
            finishedAt: null,
          },
        },
      });
    });

    it('shows when the deployment was created', () => {
      const timeago = wrapper.findComponent(TimeAgoTooltip);

      expect(timeago.text()).toBe(`Started 1 year ago by @${deployment.triggerer.username}`);
    });
  });
});
