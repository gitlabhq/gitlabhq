<script>
import { GlAlert, GlToggle } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { __, s__ } from '~/locale';
import { CC_VALIDATION_REQUIRED_ERROR } from '../constants';

const DEFAULT_ERROR_MESSAGE = __('An error occurred while updating the configuration.');
const REQUIRES_VALIDATION_TEXT = s__(
  `Billings|Shared runners cannot be enabled until a valid credit card is on file.`,
);

export default {
  i18n: {
    REQUIRES_VALIDATION_TEXT,
  },
  components: {
    GlAlert,
    GlToggle,
    CcValidationRequiredAlert: () =>
      import('ee_component/billings/components/cc_validation_required_alert.vue'),
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
    isCreditCardValidationRequired: {
      type: Boolean,
      required: false,
    },
    updatePath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
      isSharedRunnerEnabled: this.isEnabled,
      errorMessage: null,
      successfulValidation: false,
      ccAlertDismissed: false,
    };
  },
  computed: {
    ccRequiredError() {
      return this.errorMessage === CC_VALIDATION_REQUIRED_ERROR && !this.ccAlertDismissed;
    },
    genericError() {
      return (
        this.errorMessage &&
        this.errorMessage !== CC_VALIDATION_REQUIRED_ERROR &&
        !this.ccAlertDismissed
      );
    },
  },
  methods: {
    creditCardValidated() {
      this.successfulValidation = true;
    },
    toggleSharedRunners() {
      this.isLoading = true;
      this.ccAlertDismissed = false;
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
      <cc-validation-required-alert
        v-if="ccRequiredError"
        class="gl-pb-5"
        :custom-message="$options.i18n.REQUIRES_VALIDATION_TEXT"
        @verifiedCreditCard="creditCardValidated"
        @dismiss="ccAlertDismissed = true"
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

      <gl-alert
        v-if="isDisabledAndUnoverridable"
        data-testid="unoverridable-alert"
        variant="warning"
        :dismissible="false"
        class="gl-mb-5"
      >
        {{ s__('Runners|Shared runners are disabled in the group settings') }}
      </gl-alert>

      <gl-toggle
        ref="sharedRunnersToggle"
        :disabled="isDisabledAndUnoverridable"
        :is-loading="isLoading"
        :label="__('Enable shared runners for this project')"
        :value="isSharedRunnerEnabled"
        data-testid="toggle-shared-runners"
        @change="toggleSharedRunners"
      />
    </section>
  </div>
</template>
