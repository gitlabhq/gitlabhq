<script>
import { GlAlert, GlLink, GlToggle, GlSprintf } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import { IDENTITY_VERIFICATION_REQUIRED_ERROR } from '../constants';

export default {
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
      isEnabledValue: this.isEnabled,
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
    onChange() {
      this.isLoading = true;
      this.errorMessage = null;

      axios
        .post(this.updatePath)
        .then(() => {
          this.isLoading = false;
          this.isEnabledValue = !this.isEnabledValue;
        })
        .catch((error) => {
          this.isLoading = false;
          this.errorMessage =
            error.response?.data?.error ||
            __('An error occurred while updating the configuration.');
        });
    },
  },
};
</script>

<template>
  <div>
    <identity-verification-required-alert
      v-if="identityVerificationRequiredError"
      :title="
        s__(
          'IdentityVerification|Before you can use GitLab-hosted runners, we need to verify your account.',
        )
      "
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
      :disabled="isDisabledAndUnoverridable"
      :is-loading="isLoading"
      label-position="left"
      :value="isEnabledValue"
      data-testid="instance-runners-toggle"
      @change="onChange"
    >
      <template #label>
        <span class="gl-text-sm gl-font-normal gl-text-subtle">{{
          __('Enable instance runners for this project')
        }}</span>
      </template>
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
  </div>
</template>
