import { GlDisclosureDropdownItem, GlLoadingIcon, GlToast, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';

import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import RegistrationTokenResetDropdownItem from '~/ci/runner/components/registration/registration_token_reset_dropdown_item.vue';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '~/ci/runner/constants';
import runnersRegistrationTokenResetMutation from '~/ci/runner/graphql/list/runners_registration_token_reset.mutation.graphql';
import { captureException } from '~/ci/runner/sentry_utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

jest.mock('~/alert');
jest.mock('~/ci/runner/sentry_utils');

Vue.use(VueApollo);
Vue.use(GlToast);

const mockNewRegistrationToken = 'MOCK_NEW_REGISTRATION_TOKEN';
const modalID = 'token-reset-modal';

describe('RegistrationTokenResetDropdownItem', () => {
  let wrapper;
  let runnersRegistrationTokenResetMutationHandler;
  let showToast;

  const mockEvent = { preventDefault: jest.fn() };
  const findDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findModal = () => wrapper.findComponent(GlModal);
  const clickSubmit = () => findModal().vm.$emit('primary', mockEvent);

  const createComponent = ({ props, provide = {} } = {}) => {
    showToast = jest.fn();

    wrapper = shallowMount(RegistrationTokenResetDropdownItem, {
      provide,
      propsData: {
        type: INSTANCE_TYPE,
        ...props,
      },
      apolloProvider: createMockApollo([
        [runnersRegistrationTokenResetMutation, runnersRegistrationTokenResetMutationHandler],
      ]),
      directives: {
        GlModal: createMockDirective('gl-modal'),
      },
      mocks: {
        $toast: {
          show: showToast,
        },
      },
    });
  };

  beforeEach(() => {
    runnersRegistrationTokenResetMutationHandler = jest.fn().mockResolvedValue({
      data: {
        runnersRegistrationTokenReset: {
          token: mockNewRegistrationToken,
          errors: [],
        },
      },
    });

    createComponent();
  });

  it('Displays reset button', () => {
    expect(findDropdownItem().exists()).toBe(true);
  });

  describe('modal directive integration', () => {
    it('has the correct ID on the dropdown', () => {
      const binding = getBinding(findDropdownItem().element, 'gl-modal');

      expect(binding.value).toBe(modalID);
    });

    it('has the correct ID on the modal', () => {
      expect(findModal().props('modalId')).toBe(modalID);
    });
  });

  describe('On click and confirmation', () => {
    const mockGroupId = '11';
    const mockProjectId = '22';

    describe.each`
      type             | provide                         | expectedInput
      ${INSTANCE_TYPE} | ${{}}                           | ${{ type: INSTANCE_TYPE }}
      ${GROUP_TYPE}    | ${{ groupId: mockGroupId }}     | ${{ type: GROUP_TYPE, id: `gid://gitlab/Group/${mockGroupId}` }}
      ${PROJECT_TYPE}  | ${{ projectId: mockProjectId }} | ${{ type: PROJECT_TYPE, id: `gid://gitlab/Project/${mockProjectId}` }}
    `('Resets token of type $type', ({ type, provide, expectedInput }) => {
      beforeEach(async () => {
        createComponent({
          provide,
          props: { type },
        });

        findDropdownItem().trigger('click');
        clickSubmit();
        await waitForPromises();
      });

      it('resets token', () => {
        expect(runnersRegistrationTokenResetMutationHandler).toHaveBeenCalledTimes(1);
        expect(runnersRegistrationTokenResetMutationHandler).toHaveBeenCalledWith({
          input: expectedInput,
        });
      });

      it('emits result', () => {
        expect(wrapper.emitted('tokenReset')).toHaveLength(1);
        expect(wrapper.emitted('tokenReset')[0]).toEqual([mockNewRegistrationToken]);
      });

      it('does not show a loading state', () => {
        expect(findLoadingIcon().exists()).toBe(false);
      });

      it('shows confirmation', () => {
        expect(showToast).toHaveBeenLastCalledWith(
          expect.stringContaining('registration token generated'),
        );
      });
    });
  });

  describe('On click without confirmation', () => {
    beforeEach(async () => {
      findDropdownItem().vm.$emit('click');
      await waitForPromises();
    });

    it('does not reset token', () => {
      expect(runnersRegistrationTokenResetMutationHandler).not.toHaveBeenCalled();
    });

    it('does not emit any result', () => {
      expect(wrapper.emitted('tokenReset')).toBeUndefined();
    });

    it('does not show a loading state', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('does not shows confirmation', () => {
      expect(showToast).not.toHaveBeenCalled();
    });
  });

  describe('On error', () => {
    it('On network error, error message is shown', async () => {
      const mockErrorMsg = 'Token reset failed!';

      runnersRegistrationTokenResetMutationHandler.mockRejectedValueOnce(new Error(mockErrorMsg));

      findDropdownItem().trigger('click');
      clickSubmit();
      await waitForPromises();

      expect(createAlert).toHaveBeenLastCalledWith({
        message: mockErrorMsg,
      });
      expect(captureException).toHaveBeenCalledWith({
        error: new Error(mockErrorMsg),
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

      findDropdownItem().trigger('click');
      clickSubmit();
      await waitForPromises();

      expect(createAlert).toHaveBeenLastCalledWith({
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
      findDropdownItem().trigger('click');
      clickSubmit();
      await nextTick();

      expect(findLoadingIcon().exists()).toBe(true);
    });
  });
});
