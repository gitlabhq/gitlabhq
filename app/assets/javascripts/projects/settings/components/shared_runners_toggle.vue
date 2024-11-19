<script>
import { GlAlert, GlLink, GlToggle, GlSprintf } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { __, s__ } from '~/locale';
import { IDENTITY_VERIFICATION_REQUIRED_ERROR } from '../constants';

const DEFAULT_ERROR_MESSAGE = __('An error occurred while updating the configuration.');
const REQUIRES_IDENTITY_VERIFICATION_TEXT = s__(
  `IdentityVerification|Before you can use GitLab-hosted runners, we need to verify your account.`,
);

export default {
  i18n: {
    REQUIRES_IDENTITY_VERIFICATION_TEXT,
  },
  components: {
    GlAlert,
    GlLink,
    GlToggle,
    GlSprintf,
    IdentityVerificationRequiredAlert: () =>
      import('ee_component/vue_shared/components/pipeline_account_verification_alert.vue'),
  },
  props: {
    isDisabledAndUnoverridable: {
      type: Boolean,
      required: true,
    },
    isEnabled: {
      type: Boolean,
      required: true,
    },
    updatePath: {
      type: String,
      required: true,
    },
    groupName: {
      type: String,
      required: false,
      default: null,
    },
    groupSettingsPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      isLoading: false,
      isSharedRunnerEnabled: this.isEnabled,
      errorMessage: null,
    };
  },
  computed: {
    identityVerificationRequiredError() {
      return this.errorMessage === IDENTITY_VERIFICATION_REQUIRED_ERROR;
    },
    genericError() {
      return this.errorMessage && this.errorMessage !== IDENTITY_VERIFICATION_REQUIRED_ERROR;
    },
    isGroupSettingsAvailable() {
      return this.groupSettingsPath && this.groupName;
    },
  },
  methods: {
    toggleSharedRunners() {
      this.isLoading = true;
      this.errorMessage = null;

      axios
        .post(this.updatePath)
        .then(() => {
          this.isLoading = false;
          this.isSharedRunnerEnabled = !this.isSharedRunnerEnabled;
        })
        .catch((error) => {
          this.isLoading = false;
          this.errorMessage = error.response?.data?.error || DEFAULT_ERROR_MESSAGE;
        });
    },
  },
};
</script>

<template>
  <div>
    <section class="gl-mt-5">
      <identity-verification-required-alert
        v-if="identityVerificationRequiredError"
        :title="$options.i18n.REQUIRES_IDENTITY_VERIFICATION_TEXT"
        class="gl-mb-5"
      />

      <gl-alert
        v-if="genericError"
        data-testid="error-alert"
        variant="danger"
        :dismissible="false"
        class="gl-mb-5"
      >
        {{ errorMessage }}
      </gl-alert>

      <gl-toggle
        ref="sharedRunnersToggle"
        :disabled="isDisabledAndUnoverridable"
        :is-loading="isLoading"
        :label="__('Enable instance runners for this project')"
        :value="isSharedRunnerEnabled"
        data-testid="toggle-shared-runners"
        @change="toggleSharedRunners"
      >
        <template v-if="isDisabledAndUnoverridable" #help>
          {{ s__('Runners|Instance runners are disabled in the group settings.') }}
          <gl-sprintf
            v-if="isGroupSettingsAvailable"
            :message="s__('Runners|Go to %{groupLink} to enable them.')"
          >
            <template #groupLink>
              <gl-link :href="groupSettingsPath">{{ groupName }}</gl-link>
            </template>
          </gl-sprintf>
        </template>
      </gl-toggle>
    </section>
  </div>
</template>
