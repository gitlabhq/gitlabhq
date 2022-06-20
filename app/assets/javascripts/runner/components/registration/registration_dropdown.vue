<script>
import { GlDropdown, GlDropdownForm, GlDropdownItem, GlDropdownDivider } from '@gitlab/ui';
import { s__ } from '~/locale';
import RunnerInstructionsModal from '~/vue_shared/components/runner_instructions/runner_instructions_modal.vue';
import { INSTANCE_TYPE, GROUP_TYPE, PROJECT_TYPE } from '../../constants';
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
    RegistrationToken,
    RunnerInstructionsModal,
    RegistrationTokenResetDropdownItem,
  },
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
    dropdownText() {
      switch (this.type) {
        case INSTANCE_TYPE:
          return s__('Runners|Register an instance runner');
        case GROUP_TYPE:
          return s__('Runners|Register a group runner');
        case PROJECT_TYPE:
          return s__('Runners|Register a project runner');
        default:
          return s__('Runners|Register a runner');
      }
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
    variant="confirm"
    v-bind="$attrs"
  >
    <gl-dropdown-item @click.capture.native.stop="onShowInstructionsClick">
      {{ $options.i18n.showInstallationInstructions }}
      <runner-instructions-modal
        ref="runnerInstructionsModal"
        :registration-token="currentRegistrationToken"
        data-testid="runner-instructions-modal"
      />
    </gl-dropdown-item>
    <gl-dropdown-divider />
    <gl-dropdown-form class="gl-p-4!">
      <registration-token input-id="token-value" :value="currentRegistrationToken" />
    </gl-dropdown-form>
    <gl-dropdown-divider />
    <registration-token-reset-dropdown-item :type="type" @tokenReset="onTokenReset" />
  </gl-dropdown>
</template>
