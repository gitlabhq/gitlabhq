import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapse, GlIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import DeployBoardWrapper from '~/environments/components/deploy_board_wrapper.vue';
import DeployBoard from '~/environments/components/deploy_board.vue';
import setEnvironmentToChangeCanaryMutation from '~/environments/graphql/mutations/set_environment_to_change_canary.mutation.graphql';
import { resolvedEnvironment, rolloutStatus } from './graphql/mock_data';

Vue.use(VueApollo);

describe('~/environments/components/deploy_board_wrapper.vue', () => {
  let wrapper;
  let mockApollo;

  const findDeployBoard = () => wrapper.findComponent(DeployBoard);

  const createWrapper = ({ propsData = {} } = {}) => {
    mockApollo = createMockApollo();
    return mountExtended(DeployBoardWrapper, {
      propsData: { environment: resolvedEnvironment, rolloutStatus, ...propsData },
      provide: { helpPagePath: '/help' },
      apolloProvider: mockApollo,
    });
  };

  const expandCollapsedSection = async () => {
    const button = wrapper.findByRole('button', { name: 'Expand' });
    await button.trigger('click');

    return button;
  };

  afterEach(() => {
    wrapper?.destroy();
  });

  it('is labeled Kubernetes Pods', () => {
    wrapper = createWrapper();

    expect(wrapper.findByText('Kubernetes Pods').exists()).toBe(true);
  });

  describe('collapse', () => {
    let icon;
    let collapse;

    beforeEach(() => {
      wrapper = createWrapper();
      collapse = wrapper.findComponent(GlCollapse);
      icon = wrapper.findComponent(GlIcon);
    });

    it('is collapsed by default', () => {
      expect(collapse.props('visible')).toBe(false);
      expect(icon.props('name')).toBe('chevron-lg-right');
    });

    it('opens on click', async () => {
      const button = await expandCollapsedSection();

      expect(button.attributes('aria-label')).toBe('Collapse');
      expect(collapse.props('visible')).toBe(true);
      expect(icon.props('name')).toBe('chevron-lg-down');

      const deployBoard = findDeployBoard();
      expect(deployBoard.exists()).toBe(true);
    });
  });

  describe('deploy board', () => {
    it('passes the rollout status on and sets graphql to true', async () => {
      wrapper = createWrapper();
      await expandCollapsedSection();

      const deployBoard = findDeployBoard();
      expect(deployBoard.props('deployBoardData')).toEqual(rolloutStatus);
      expect(deployBoard.props('graphql')).toBe(true);
    });

    it('sets the update to the canary via graphql', () => {
      wrapper = createWrapper();
      jest.spyOn(mockApollo.defaultClient, 'mutate');
      const deployBoard = findDeployBoard();
      deployBoard.vm.$emit('changeCanaryWeight', 15);
      expect(mockApollo.defaultClient.mutate).toHaveBeenCalledWith({
        mutation: setEnvironmentToChangeCanaryMutation,
        variables: { environment: resolvedEnvironment, weight: 15 },
      });
    });

    describe('is loading', () => {
      it('should set the loading prop', async () => {
        wrapper = createWrapper({
          propsData: { rolloutStatus: { ...rolloutStatus, status: 'loading' } },
        });

        await expandCollapsedSection();

        const deployBoard = findDeployBoard();

        expect(deployBoard.props('isLoading')).toBe(true);
      });
    });

    describe('is empty', () => {
      it('should set the empty prop', async () => {
        wrapper = createWrapper({
          propsData: { rolloutStatus: { ...rolloutStatus, status: 'not_found' } },
        });

        await expandCollapsedSection();

        const deployBoard = findDeployBoard();

        expect(deployBoard.props('isEmpty')).toBe(true);
      });
    });
  });
});
