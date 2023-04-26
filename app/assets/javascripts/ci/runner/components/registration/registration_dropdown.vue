<script>
import { GlDropdown, GlDropdownForm, GlDropdownItem, GlDropdownDivider, GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import RunnerInstructionsModal from '~/vue_shared/components/runner_instructions/runner_instructions_modal.vue';
import {
  INSTANCE_TYPE,
  GROUP_TYPE,
  PROJECT_TYPE,
  I18N_REGISTER_INSTANCE_TYPE,
  I18N_REGISTER_GROUP_TYPE,
  I18N_REGISTER_PROJECT_TYPE,
  I18N_REGISTER_RUNNER,
} from '../../constants';
import RegistrationToken from './registration_token.vue';
import RegistrationTokenResetDropdownItem from './registration_token_reset_dropdown_item.vue';

export default {
  i18n: {
    showInstallationInstructions: s__(
      'Runners|Show runner installation and registration instructions',
    ),
  },
  components: {
    GlDropdown,
    GlDropdownForm,
    GlDropdownItem,
    GlDropdownDivider,
    GlIcon,
    RegistrationToken,
    RunnerInstructionsModal,
    RegistrationTokenResetDropdownItem,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    registrationToken: {
      type: String,
      required: true,
    },
    type: {
      type: String,
      required: true,
      validator(type) {
        return [INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE].includes(type);
      },
    },
  },
  data() {
    return {
      currentRegistrationToken: this.registrationToken,
    };
  },
  computed: {
    isDeprecated() {
      // Show a compact version when used as secondary option
      // create_runner_workflow_for_admin or create_runner_workflow_for_namespace
      return (
        this.glFeatures?.createRunnerWorkflowForAdmin ||
        this.glFeatures?.createRunnerWorkflowForNamespace
      );
    },
    actionText() {
      switch (this.type) {
        case INSTANCE_TYPE:
          return I18N_REGISTER_INSTANCE_TYPE;
        case GROUP_TYPE:
          return I18N_REGISTER_GROUP_TYPE;
        case PROJECT_TYPE:
          return I18N_REGISTER_PROJECT_TYPE;
        default:
          return I18N_REGISTER_RUNNER;
      }
    },
    dropdownText() {
      if (this.isDeprecated) {
        return '';
      }
      return this.actionText;
    },
    dropdownToggleClass() {
      if (this.isDeprecated) {
        return ['gl-px-3!'];
      }
      return [];
    },
    dropdownCategory() {
      if (this.isDeprecated) {
        return 'tertiary';
      }
      return 'primary';
    },
    dropdownVariant() {
      if (this.isDeprecated) {
        return 'default';
      }
      return 'confirm';
    },
  },
  methods: {
    onShowInstructionsClick() {
      this.$refs.runnerInstructionsModal.show();
    },
    onTokenReset(token) {
      this.currentRegistrationToken = token;

      this.$refs.runnerRegistrationDropdown.hide(true);
    },
  },
};
</script>

<template>
  <gl-dropdown
    ref="runnerRegistrationDropdown"
    menu-class="gl-w-auto!"
    :text="dropdownText"
    :toggle-class="dropdownToggleClass"
    :variant="dropdownVariant"
    :category="dropdownCategory"
    v-bind="$attrs"
  >
    <template v-if="isDeprecated" #button-content>
      <span class="gl-sr-only">{{ actionText }}</span>
      <gl-icon name="ellipsis_v" />
    </template>
    <gl-dropdown-form class="gl-p-4!">
      <registration-token input-id="token-value" :value="currentRegistrationToken">
        <template v-if="isDeprecated" #label-description>
          <gl-icon name="warning" class="gl-text-orange-500" />
          <span class="gl-text-secondary">
            {{ s__('Runners|Support for registration tokens is deprecated') }}
          </span>
        </template>
      </registration-token>
    </gl-dropdown-form>
    <gl-dropdown-divider />
    <gl-dropdown-item @click.capture.native.stop="onShowInstructionsClick">
      {{ $options.i18n.showInstallationInstructions }}
      <runner-instructions-modal
        ref="runnerInstructionsModal"
        :registration-token="currentRegistrationToken"
        data-testid="runner-instructions-modal"
      />
    </gl-dropdown-item>
    <gl-dropdown-divider />
    <registration-token-reset-dropdown-item :type="type" @tokenReset="onTokenReset" />
  </gl-dropdown>
</template>
