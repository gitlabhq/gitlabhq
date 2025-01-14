<script>
import {
  GlDisclosureDropdown,
  GlDropdownForm,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
  GlIcon,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import RunnerInstructionsModal from '~/ci/runner/components/registration/runner_instructions/runner_instructions_modal.vue';
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

const REGISTRATION_TOKEN_ENABLED = 'REGISTRATION_TOKEN_ENABLED';
const REGISTRATION_TOKEN_DISABLED = 'REGISTRATION_TOKEN_DISABLED';
const REGISTRATION_TOKEN_HIDDEN = 'REGISTRATION_TOKEN_HIDDEN';

export default {
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlDisclosureDropdownGroup,
    GlDropdownForm,
    GlIcon,
    GlLink,
    GlSprintf,
    RegistrationToken,
    RunnerInstructionsModal,
    RegistrationTokenResetDropdownItem,
  },
  props: {
    allowRegistrationToken: {
      type: Boolean,
      required: false,
      default: false,
    },
    registrationToken: {
      type: String,
      required: false,
      default: null,
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
    isRegistrationTokenPresent() {
      return Boolean(this.registrationToken);
    },
    state() {
      if (this.registrationToken && this.allowRegistrationToken) {
        // Legacy registration with registration token can be used, will be fully removed by 18.0
        return REGISTRATION_TOKEN_ENABLED;
      }
      if (!this.allowRegistrationToken) {
        // If registration is disabled by admins or group owners, display the dropdown with a message
        return REGISTRATION_TOKEN_DISABLED;
      }

      // If registration is still enabled for the instance or group, but the user cannot see the
      // token due to permissions, hide this control as they don't have access
      return REGISTRATION_TOKEN_HIDDEN;
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
  REGISTRATION_TOKEN_ENABLED,
  REGISTRATION_TOKEN_DISABLED,
  REGISTRATION_TOKEN_HIDDEN,
  registrationTokenDisabledHelpPagePath: helpPagePath('ci/runners/new_creation_workflow.html', {
    anchor: 'using-registration-tokens-after-gitlab-170',
  }),
};
</script>

<template>
  <gl-disclosure-dropdown
    v-if="state !== $options.REGISTRATION_TOKEN_HIDDEN"
    ref="runnerRegistrationDropdown"
    :toggle-text="actionText"
    toggle-class="!gl-px-3"
    variant="default"
    category="tertiary"
    v-bind="$attrs"
    icon="ellipsis_v"
    text-sr-only
    no-caret
  >
    <div v-if="state == $options.REGISTRATION_TOKEN_DISABLED" class="gl-px-4 gl-py-2">
      <gl-icon name="error" variant="danger" />
      <gl-sprintf
        :message="
          s__(
            'Runners|Creating runners with runner registration tokens is disabled. %{linkStart}Learn more%{linkEnd}.',
          )
        "
      >
        <template #link="{ content }"
          ><gl-link :href="$options.registrationTokenDisabledHelpPagePath">{{
            content
          }}</gl-link></template
        >
      </gl-sprintf>
    </div>
    <template v-if="state == $options.REGISTRATION_TOKEN_ENABLED">
      <gl-dropdown-form class="!gl-p-4">
        <registration-token input-id="token-value" :value="currentRegistrationToken" @copy="onCopy">
          <template #label-description>
            <gl-icon name="warning" variant="warning" />
            <span class="gl-text-subtle">
              {{ s__('Runners|Support for registration tokens is deprecated') }}
            </span>
          </template>
        </registration-token>
      </gl-dropdown-form>
      <gl-disclosure-dropdown-group bordered>
        <gl-disclosure-dropdown-item @action="onShowInstructionsClick">
          <template #list-item>
            {{ s__('Runners|Show runner installation and registration instructions') }}
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
    </template>
  </gl-disclosure-dropdown>
</template>
