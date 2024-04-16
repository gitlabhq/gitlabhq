import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlIcon, GlAlert, GlButton } from '@gitlab/ui';
import mockDeploymentFixture from 'test_fixtures/graphql/deployments/graphql/queries/deployment.query.graphql.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import DeploymentDeployBlock from '~/deployments/components/deployment_deploy_block.vue';
import deployMutation from '~/deployments/graphql/mutations/deploy.mutation.graphql';

jest.mock('~/sentry/sentry_browser_wrapper');

const {
  data: {
    project: { deployment },
  },
} = mockDeploymentFixture;

Vue.use(VueApollo);

describe('~/deployments/components/deployment_deploy_block.vue', () => {
  let wrapper;
  let mockDeploy;

  const createComponent = ({ propsData = {} } = {}) => {
    const apolloProvider = createMockApollo([[deployMutation, mockDeploy]]);
    wrapper = shallowMountExtended(DeploymentDeployBlock, {
      apolloProvider,
      propsData: {
        deployment,
        ...propsData,
      },
    });
  };

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findAlert = () => wrapper.findComponent(GlAlert);

  beforeEach(() => {
    mockDeploy = jest.fn();
  });

  describe('with manual job user can play', () => {
    let button;

    beforeEach(() => {
      createComponent();
      button = wrapper.findComponent(GlButton);
      mockDeploy.mockResolvedValue({ data: { jobPlay: { errors: [] } } });
    });

    it('shows the block if the job is ready to play', () => {
      expect(wrapper.find('div').exists()).toBe(true);
    });

    it('displays text and icon saying user can deploy', () => {
      expect(findIcon().props('name')).toBe('check-circle-filled');
      expect(wrapper.findByText('Ready to be deployed.').exists()).toBe(true);
    });

    it('displays a button that starts the job', () => {
      button.vm.$emit('click');

      expect(mockDeploy).toHaveBeenCalledWith({ input: { id: deployment.job.id } });
    });

    describe('with data error', () => {
      let error;

      beforeEach(() => {
        error = 'oh no!';
        mockDeploy.mockResolvedValue({ data: { jobPlay: { errors: [error] } } });
        button.vm.$emit('click');
        return waitForPromises();
      });

      it('shows an error message', () => {
        expect(findAlert().text()).toBe(error);
      });
    });

    describe('with generic error', () => {
      let error;

      beforeEach(() => {
        error = new Error('oops!');
        mockDeploy.mockRejectedValue(error);
        button.vm.$emit('click');
        return waitForPromises();
      });

      it('shows an error message', () => {
        expect(findAlert().text()).toBe(
          'Something went wrong starting the deployment. Please try again later.',
        );
      });

      it('sends the error to sentry', () => {
        expect(captureException).toHaveBeenCalledWith(error);
      });
    });
  });

  describe('with manual job user can not play', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          deployment: {
            ...deployment,
            job: {
              ...deployment.job,
              canPlayJob: false,
            },
          },
        },
      });
    });

    it('shows the block if the job is ready to play', () => {
      expect(wrapper.find('div').exists()).toBe(true);
    });

    it('displays text and icon saying deploy is pending', () => {
      expect(findIcon().props('name')).toBe('timer');
      expect(wrapper.findByText('Waiting to be deployed.').exists()).toBe(true);
    });
  });

  describe('with non-manual job', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          deployment: {
            ...deployment,
            job: {
              ...deployment.job,
              playable: false,
            },
          },
        },
      });
    });

    it('shows nothing', () => {
      expect(wrapper.find('div').exists()).toBe(false);
    });
  });
});
