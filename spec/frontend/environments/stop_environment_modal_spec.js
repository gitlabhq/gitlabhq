import { GlModal, GlSprintf, GlFormCheckbox } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import StopEnvironmentModal from '~/environments/components/stop_environment_modal.vue';
import stopEnvironmentMutation from '~/environments/graphql/mutations/stop_environment.mutation.graphql';
import { resolvedEnvironment } from './graphql/mock_data';

Vue.use(VueApollo);

describe('StopEnvironmentModal', () => {
  let wrapper;
  let mockApollo;

  const createWrapper = ({ environment = resolvedEnvironment } = {}) => {
    mockApollo = createMockApollo();
    jest.spyOn(mockApollo.defaultClient, 'mutate');

    wrapper = shallowMountExtended(StopEnvironmentModal, {
      apolloProvider: mockApollo,
      propsData: { environment },
      stubs: { GlSprintf, GlModal, GlFormCheckbox },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findModalText = () => findModal().text().replace(/\s+/g, ' ');
  const findMessage = () => wrapper.findByTestId('stop-environment-message');
  const findForceStopCheckbox = () => wrapper.findComponent(GlFormCheckbox);

  const submitModal = () => findModal().vm.$emit('primary');

  describe('when the environment has no stop action', () => {
    beforeEach(() => {
      createWrapper({ environment: { ...resolvedEnvironment, hasStopAction: false } });
    });

    it('renders the stop title and primary action', () => {
      expect(findModalText()).toContain(`Stop ${resolvedEnvironment.name}?`);
      expect(findModal().props('actionPrimary')).toMatchObject({ text: 'Stop environment' });
    });

    it('renders no action:stop is defined message', () => {
      expect(findMessage().text()).toMatchInterpolatedText(
        `You are about to stop the environment ${resolvedEnvironment.name}. The environment will be moved to the Stopped tab. There is no action:stop defined for this environment, so your existing deployments will not be affected. Learn more about stopping environments.`,
      );
    });

    it('does not render the force stop option', () => {
      expect(findForceStopCheckbox().exists()).toBe(false);
    });

    it('stops the environment without forcing on submit', () => {
      submitModal();

      expect(mockApollo.defaultClient.mutate).toHaveBeenCalledWith({
        mutation: stopEnvironmentMutation,
        variables: {
          environment: { ...resolvedEnvironment, hasStopAction: false },
          force: false,
        },
      });
    });
  });

  describe('when the environment has a stop action', () => {
    const environment = { ...resolvedEnvironment, hasStopAction: true };

    beforeEach(() => {
      createWrapper({ environment });
    });

    it('renders the force stop option unchecked', () => {
      expect(findForceStopCheckbox().exists()).toBe(true);
      expect(findForceStopCheckbox().text()).toContain('Force stop');
      expect(findForceStopCheckbox().text()).toContain('Skip the action:stop job');
      expect(findModal().props('actionPrimary')).toMatchObject({ text: 'Stop environment' });
    });

    it('stops the environment without forcing by default', () => {
      submitModal();

      expect(mockApollo.defaultClient.mutate).toHaveBeenCalledWith({
        mutation: stopEnvironmentMutation,
        variables: { environment, force: false },
      });
    });

    describe('when force stop is selected', () => {
      beforeEach(async () => {
        findForceStopCheckbox().vm.$emit('input', true);
        await nextTick();
      });

      it('changes the primary action text', () => {
        expect(findModal().props('actionPrimary')).toMatchObject({
          text: 'Force stop environment',
        });
      });

      it('force stops the environment on submit', () => {
        submitModal();

        expect(mockApollo.defaultClient.mutate).toHaveBeenCalledWith({
          mutation: stopEnvironmentMutation,
          variables: { environment, force: true },
        });
      });

      it('resets the option when the modal is hidden', async () => {
        findModal().vm.$emit('hidden');
        await nextTick();

        expect(findModal().props('actionPrimary')).toMatchObject({ text: 'Stop environment' });
      });
    });
  });

  describe('when the environment is stopping', () => {
    const environment = { ...resolvedEnvironment, state: 'stopping', hasStopAction: false };

    beforeEach(() => {
      createWrapper({ environment });
    });

    it('renders the force stop title and primary action', () => {
      expect(findModalText()).toContain(`Force stop ${resolvedEnvironment.name}?`);
      expect(findModal().props('actionPrimary')).toMatchObject({
        text: 'Force stop environment',
      });
    });

    it('renders the forced stop message', () => {
      expect(findMessage().text()).toMatchInterpolatedText(
        `The environment ${resolvedEnvironment.name} is currently stopping. Force stopping marks it as stopped immediately and moves it to the Stopped tab, without running or waiting for its action:stop job. Resources deployed to this environment might not be cleaned up. Learn more about stopping environments.`,
      );
    });

    it('does not render the force stop option', () => {
      expect(findForceStopCheckbox().exists()).toBe(false);
    });

    it('force stops the environment on submit', () => {
      submitModal();

      expect(mockApollo.defaultClient.mutate).toHaveBeenCalledWith({
        mutation: stopEnvironmentMutation,
        variables: { environment, force: true },
      });
    });
  });
});
