import { GlButton } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash, { FLASH_TYPES } from '~/flash';
import RunnerRegistrationTokenReset from '~/runner/components/runner_registration_token_reset.vue';
import { INSTANCE_TYPE } from '~/runner/constants';
import runnersRegistrationTokenResetMutation from '~/runner/graphql/runners_registration_token_reset.mutation.graphql';
import { captureException } from '~/runner/sentry_utils';

jest.mock('~/flash');
jest.mock('~/runner/sentry_utils');

const localVue = createLocalVue();
localVue.use(VueApollo);

const mockNewToken = 'NEW_TOKEN';

describe('RunnerRegistrationTokenReset', () => {
  let wrapper;
  let runnersRegistrationTokenResetMutationHandler;

  const findButton = () => wrapper.findComponent(GlButton);

  const createComponent = () => {
    wrapper = shallowMount(RunnerRegistrationTokenReset, {
      localVue,
      propsData: {
        type: INSTANCE_TYPE,
      },
      apolloProvider: createMockApollo([
        [runnersRegistrationTokenResetMutation, runnersRegistrationTokenResetMutationHandler],
      ]),
    });
  };

  beforeEach(() => {
    runnersRegistrationTokenResetMutationHandler = jest.fn().mockResolvedValue({
      data: {
        runnersRegistrationTokenReset: {
          token: mockNewToken,
          errors: [],
        },
      },
    });

    createComponent();

    jest.spyOn(window, 'confirm');
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays reset button', () => {
    expect(findButton().exists()).toBe(true);
  });

  describe('On click and confirmation', () => {
    beforeEach(async () => {
      window.confirm.mockReturnValueOnce(true);
      await findButton().vm.$emit('click');
    });

    it('resets token', () => {
      expect(runnersRegistrationTokenResetMutationHandler).toHaveBeenCalledTimes(1);
      expect(runnersRegistrationTokenResetMutationHandler).toHaveBeenCalledWith({
        input: { type: INSTANCE_TYPE },
      });
    });

    it('emits result', () => {
      expect(wrapper.emitted('tokenReset')).toHaveLength(1);
      expect(wrapper.emitted('tokenReset')[0]).toEqual([mockNewToken]);
    });

    it('does not show a loading state', () => {
      expect(findButton().props('loading')).toBe(false);
    });

    it('shows confirmation', () => {
      expect(createFlash).toHaveBeenLastCalledWith({
        message: expect.stringContaining('registration token generated'),
        type: FLASH_TYPES.SUCCESS,
      });
    });
  });

  describe('On click without confirmation', () => {
    beforeEach(async () => {
      window.confirm.mockReturnValueOnce(false);
      await findButton().vm.$emit('click');
    });

    it('does not reset token', () => {
      expect(runnersRegistrationTokenResetMutationHandler).not.toHaveBeenCalled();
    });

    it('does not emit any result', () => {
      expect(wrapper.emitted('tokenReset')).toBeUndefined();
    });

    it('does not show a loading state', () => {
      expect(findButton().props('loading')).toBe(false);
    });

    it('does not shows confirmation', () => {
      expect(createFlash).not.toHaveBeenCalled();
    });
  });

  describe('On error', () => {
    it('On network error, error message is shown', async () => {
      const mockErrorMsg = 'Token reset failed!';

      runnersRegistrationTokenResetMutationHandler.mockRejectedValueOnce(new Error(mockErrorMsg));

      window.confirm.mockReturnValueOnce(true);
      await findButton().vm.$emit('click');
      await waitForPromises();

      expect(createFlash).toHaveBeenLastCalledWith({
        message: `Network error: ${mockErrorMsg}`,
      });
      expect(captureException).toHaveBeenCalledWith({
        error: new Error(`Network error: ${mockErrorMsg}`),
        component: 'RunnerRegistrationTokenReset',
      });
    });

    it('On validation error, error message is shown', async () => {
      const mockErrorMsg = 'User not allowed!';
      const mockErrorMsg2 = 'Type is not valid!';

      runnersRegistrationTokenResetMutationHandler.mockResolvedValue({
        data: {
          runnersRegistrationTokenReset: {
            token: null,
            errors: [mockErrorMsg, mockErrorMsg2],
          },
        },
      });

      window.confirm.mockReturnValueOnce(true);
      await findButton().vm.$emit('click');
      await waitForPromises();

      expect(createFlash).toHaveBeenLastCalledWith({
        message: `${mockErrorMsg} ${mockErrorMsg2}`,
      });
      expect(captureException).toHaveBeenCalledWith({
        error: new Error(`${mockErrorMsg} ${mockErrorMsg2}`),
        component: 'RunnerRegistrationTokenReset',
      });
    });
  });

  describe('Immediately after click', () => {
    it('shows loading state', async () => {
      window.confirm.mockReturnValue(true);
      await findButton().vm.$emit('click');

      expect(findButton().props('loading')).toBe(true);
    });
  });
});
