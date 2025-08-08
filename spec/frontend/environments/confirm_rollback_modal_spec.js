import { GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { trimText } from 'helpers/text_helper';
import { createAlert } from '~/alert';
import ConfirmRollbackModal from '~/environments/components/confirm_rollback_modal.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('Confirm Rollback Modal Component', () => {
  let environment;
  let component;

  const envWithLastDeployment = {
    name: 'test',
    lastDeployment: {
      commit: {
        shortId: 'abc0123',
      },
    },
    modalId: 'test',
  };

  const envWithoutLastDeployment = {
    name: 'test',
    modalId: 'test',
    commitShortSha: 'abc0123',
    commitUrl: 'test/-/commit/abc0123',
  };

  const retryPath = 'test/-/jobs/123/retry';
  const rollbackResolver = jest.fn();

  const createComponent = (props = {}, options = {}) => {
    const mockApollo = createMockApollo([], {
      Mutation: { rollbackEnvironment: rollbackResolver },
    });

    component = shallowMount(ConfirmRollbackModal, {
      apolloProvider: mockApollo,
      propsData: {
        ...props,
      },
      stubs: {
        GlSprintf,
      },
      ...options,
    });
  };

  const findModal = () => component.findComponent(GlModal);

  const confirmModal = () => {
    findModal().vm.$emit('primary');

    return waitForPromises();
  };

  describe.each`
    hasMultipleCommits | environmentData             | retryUrl     | primaryPropsAttrs
    ${true}            | ${envWithLastDeployment}    | ${null}      | ${[{ variant: 'danger' }]}
    ${false}           | ${envWithoutLastDeployment} | ${retryPath} | ${[{ variant: 'danger' }, { 'data-method': 'post' }, { href: retryPath }]}
  `(
    'when hasMultipleCommits=$hasMultipleCommits',
    ({ hasMultipleCommits, environmentData, retryUrl, primaryPropsAttrs }) => {
      beforeEach(() => {
        environment = environmentData;
      });

      it('should show "Rollback" when isLastDeployment is false', () => {
        createComponent({
          environment: {
            ...environment,
            isLastDeployment: false,
          },
          hasMultipleCommits,
          retryUrl,
        });

        const modal = findModal();

        expect(modal.attributes('title')).toContain('Rollback');
        expect(modal.attributes('title')).toContain('test');
        expect(modal.props('actionPrimary').text).toBe('Rollback environment');
        expect(modal.props('actionPrimary').attributes).toEqual(primaryPropsAttrs);
        expect(trimText(modal.text())).toContain('commit abc0123');
        expect(modal.text()).toContain('Are you sure you want to continue?');
      });

      it('should show "Re-deploy" when isLastDeployment is true', () => {
        createComponent({
          environment: {
            ...environment,
            isLastDeployment: true,
          },
          hasMultipleCommits,
        });

        const modal = findModal();

        expect(modal.attributes('title')).toContain('Re-deploy');
        expect(modal.attributes('title')).toContain('test');
        expect(modal.props('actionPrimary').text).toBe('Re-deploy environment');
        expect(trimText(modal.text())).toContain('commit abc0123');
        expect(modal.text()).toContain('Are you sure you want to continue?');
      });

      it('should commit the "rollback" mutation when primary action is clicked', async () => {
        const env = { ...environmentData, isLastDeployment: true };

        createComponent({
          environment: env,
          hasMultipleCommits,
        });

        await confirmModal();

        expect(rollbackResolver).toHaveBeenCalledWith(
          expect.anything(),
          { environment: env },
          expect.anything(),
          expect.anything(),
        );
      });

      it('should emit the "rollback" event when primary action is clicked', async () => {
        const env = { ...environmentData, isLastDeployment: true };

        createComponent({
          environment: env,
          hasMultipleCommits,
        });

        await confirmModal();

        expect(component.emitted('rollback')).toEqual([[]]);
      });
    },
  );

  describe('on error', () => {
    const error = 'This is error';
    beforeEach(async () => {
      rollbackResolver.mockResolvedValue({
        errors: [error],
      });

      const env = { ...envWithLastDeployment, isLastDeployment: true };

      createComponent({
        environment: env,
        hasMultipleCommits: true,
      });

      await confirmModal();
    });

    it('should render alert when the rollback action failed', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: error,
        error: new Error(error),
        captureError: true,
      });
    });

    it('should not emit the rollback event', () => {
      expect(component.emitted('rollback')).toBeUndefined();
    });
  });

  describe('on network error', () => {
    const error = new Error('Network error!');

    beforeEach(async () => {
      rollbackResolver.mockRejectedValue(error);

      const env = { ...envWithLastDeployment, isLastDeployment: true };

      createComponent({
        environment: env,
        hasMultipleCommits: true,
      });

      await confirmModal();
    });

    it('should render alert when the rollback action failed', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong. Please try again.',
        error,
        captureError: true,
      });
    });

    it('should not emit the rollback event', () => {
      expect(component.emitted('rollback')).toBeUndefined();
    });
  });
});
