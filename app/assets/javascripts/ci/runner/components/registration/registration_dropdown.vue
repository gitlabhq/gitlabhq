<script>
import {
  GlDisclosureDropdown,
  GlDropdownForm,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
  GlIcon,
} from '@gitlab/ui';
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
    supportForRegistrationTokensDeprecated: s__(
      'Runners|Support for registration tokens is deprecated',
    ),
  },
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlDisclosureDropdownGroup,
    GlDropdownForm,
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
  },
  methods: {
    onShowInstructionsClick() {
      this.$refs.runnerInstructionsModal.show();
    },
    onTokenReset(token) {
      this.currentRegistrationToken = token;

      this.$refs.runnerRegistrationDropdown.close();
    },
    onCopy() {
      this.$refs.runnerRegistrationDropdown.close();
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    ref="runnerRegistrationDropdown"
    :toggle-text="actionText"
    toggle-class="gl-px-3!"
    variant="default"
    category="tertiary"
    v-bind="$attrs"
    icon="ellipsis_v"
    text-sr-only
    no-caret
  >
    <gl-dropdown-form class="gl-p-4!">
      <registration-token input-id="token-value" :value="currentRegistrationToken" @copy="onCopy">
        <template #label-description>
          <gl-icon name="warning" class="gl-text-orange-500" />
          <span class="gl-text-secondary">
            {{ $options.i18n.supportForRegistrationTokensDeprecated }}
          </span>
        </template>
      </registration-token>
    </gl-dropdown-form>
    <gl-disclosure-dropdown-group bordered>
      <gl-disclosure-dropdown-item @action="onShowInstructionsClick">
        <template #list-item>
          {{ $options.i18n.showInstallationInstructions }}
          <runner-instructions-modal
            ref="runnerInstructionsModal"
            :registration-token="currentRegistrationToken"
            data-testid="runner-instructions-modal"
          />
        </template>
      </gl-disclosure-dropdown-item>
    </gl-disclosure-dropdown-group>
    <gl-disclosure-dropdown-group bordered>
      <registration-token-reset-dropdown-item :type="type" @tokenReset="onTokenReset" />
    </gl-disclosure-dropdown-group>
  </gl-disclosure-dropdown>
</template>
