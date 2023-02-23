import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { createAlert, VARIANT_SUCCESS } from '~/flash';

import AdminNewRunnerApp from '~/ci/runner/admin_new_runner/admin_new_runner_app.vue';
import { saveAlertToLocalStorage } from '~/ci/runner/local_storage_alert/save_alert_to_local_storage';
import RunnerInstructionsModal from '~/vue_shared/components/runner_instructions/runner_instructions_modal.vue';
import RunnerPlatformsRadioGroup from '~/ci/runner/components/runner_platforms_radio_group.vue';
import { PARAM_KEY_PLATFORM, DEFAULT_PLATFORM, WINDOWS_PLATFORM } from '~/ci/runner/constants';
import RunnerCreateForm from '~/ci/runner/components/runner_create_form.vue';
import { redirectTo } from '~/lib/utils/url_utility';
import { runnerCreateResult } from '../mock_data';

const mockLegacyRegistrationToken = 'LEGACY_REGISTRATION_TOKEN';

Vue.use(VueApollo);

jest.mock('~/ci/runner/local_storage_alert/save_alert_to_local_storage');
jest.mock('~/flash');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  redirectTo: jest.fn(),
}));

const mockCreatedRunner = runnerCreateResult.data.runnerCreate.runner;

describe('AdminNewRunnerApp', () => {
  let wrapper;

  const findLegacyInstructionsLink = () => wrapper.findByTestId('legacy-instructions-link');
  const findRunnerInstructionsModal = () => wrapper.findComponent(RunnerInstructionsModal);
  const findRunnerPlatformsRadioGroup = () => wrapper.findComponent(RunnerPlatformsRadioGroup);
  const findRunnerCreateForm = () => wrapper.findComponent(RunnerCreateForm);

  const createComponent = () => {
    wrapper = shallowMountExtended(AdminNewRunnerApp, {
      propsData: {
        legacyRegistrationToken: mockLegacyRegistrationToken,
      },
      directives: {
        GlModal: createMockDirective('gl-modal'),
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('Shows legacy modal', () => {
    it('passes legacy registration to modal', () => {
      expect(findRunnerInstructionsModal().props('registrationToken')).toEqual(
        mockLegacyRegistrationToken,
      );
    });

    it('opens a modal with the legacy instructions', () => {
      const modalId = getBinding(findLegacyInstructionsLink().element, 'gl-modal').value;

      expect(findRunnerInstructionsModal().props('modalId')).toBe(modalId);
    });
  });

  describe('Platform', () => {
    it('shows the platforms radio group', () => {
      expect(findRunnerPlatformsRadioGroup().props('value')).toBe(DEFAULT_PLATFORM);
    });
  });

  describe('Runner form', () => {
    it('shows the runner create form', () => {
      expect(findRunnerCreateForm().exists()).toBe(true);
    });

    describe('When a runner is saved', () => {
      beforeEach(() => {
        findRunnerCreateForm().vm.$emit('saved', mockCreatedRunner);
      });

      it('pushes an alert to be shown after redirection', () => {
        expect(saveAlertToLocalStorage).toHaveBeenCalledWith({
          message: s__('Runners|Runner created.'),
          variant: VARIANT_SUCCESS,
        });
      });

      it('redirects to the registration page', () => {
        const url = `${mockCreatedRunner.registerAdminUrl}?${PARAM_KEY_PLATFORM}=${DEFAULT_PLATFORM}`;

        expect(redirectTo).toHaveBeenCalledWith(url);
      });
    });

    describe('When another platform is selected and a runner is saved', () => {
      beforeEach(() => {
        findRunnerPlatformsRadioGroup().vm.$emit('input', WINDOWS_PLATFORM);
        findRunnerCreateForm().vm.$emit('saved', mockCreatedRunner);
      });

      it('redirects to the registration page with the platform', () => {
        const url = `${mockCreatedRunner.registerAdminUrl}?${PARAM_KEY_PLATFORM}=${WINDOWS_PLATFORM}`;

        expect(redirectTo).toHaveBeenCalledWith(url);
      });
    });

    describe('When runner fails to save', () => {
      const ERROR_MSG = 'Cannot save!';

      beforeEach(() => {
        findRunnerCreateForm().vm.$emit('error', new Error(ERROR_MSG));
      });

      it('shows an error message', () => {
        expect(createAlert).toHaveBeenCalledWith({ message: ERROR_MSG });
      });
    });
  });
});
