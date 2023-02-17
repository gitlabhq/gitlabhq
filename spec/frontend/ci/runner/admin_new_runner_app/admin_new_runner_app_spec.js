import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

import AdminNewRunnerApp from '~/ci/runner/admin_new_runner/admin_new_runner_app.vue';
import RunnerInstructionsModal from '~/vue_shared/components/runner_instructions/runner_instructions_modal.vue';
import RunnerPlatformsRadioGroup from '~/ci/runner/components/runner_platforms_radio_group.vue';
import RunnerFormFields from '~/ci/runner/components/runner_form_fields.vue';
import { DEFAULT_PLATFORM } from '~/ci/runner/constants';

const mockLegacyRegistrationToken = 'LEGACY_REGISTRATION_TOKEN';

Vue.use(VueApollo);

describe('AdminNewRunnerApp', () => {
  let wrapper;

  const findLegacyInstructionsLink = () => wrapper.findByTestId('legacy-instructions-link');
  const findRunnerInstructionsModal = () => wrapper.findComponent(RunnerInstructionsModal);
  const findRunnerPlatformsRadioGroup = () => wrapper.findComponent(RunnerPlatformsRadioGroup);
  const findRunnerFormFields = () => wrapper.findComponent(RunnerFormFields);

  const createComponent = ({ props = {}, mountFn = shallowMountExtended, ...options } = {}) => {
    wrapper = mountFn(AdminNewRunnerApp, {
      propsData: {
        legacyRegistrationToken: mockLegacyRegistrationToken,
        ...props,
      },
      directives: {
        GlModal: createMockDirective(),
      },
      stubs: {
        GlSprintf,
      },
      ...options,
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

  describe('New runner form fields', () => {
    describe('Platform', () => {
      it('shows the platforms radio group', () => {
        expect(findRunnerPlatformsRadioGroup().props('value')).toBe(DEFAULT_PLATFORM);
      });
    });

    describe('Runner', () => {
      it('shows the runners fields', () => {
        expect(findRunnerFormFields().props('value')).toEqual({
          accessLevel: 'NOT_PROTECTED',
          paused: false,
          description: '',
          maintenanceNote: '',
          maximumTimeout: ' ',
          runUntagged: false,
          tagList: '',
        });
      });
    });
  });
});
