<script>
import { GlAlert, GlToggle, GlTooltip } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { __, s__ } from '~/locale';

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
    GlTooltip,
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
    };
  },
  computed: {
    showCreditCardValidation() {
      return (
        this.isCreditCardValidationRequired &&
        !this.isSharedRunnerEnabled &&
        !this.successfulValidation
      );
    },
  },
  methods: {
    creditCardValidated() {
      this.successfulValidation = true;
    },
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
      <gl-alert v-if="errorMessage" class="gl-mb-3" variant="danger" :dismissible="false">
        {{ errorMessage }}
      </gl-alert>

      <cc-validation-required-alert
        v-if="showCreditCardValidation"
        class="gl-pb-5"
        :custom-message="$options.i18n.REQUIRES_VALIDATION_TEXT"
        @verifiedCreditCard="creditCardValidated"
      />

      <gl-toggle
        v-else
        ref="sharedRunnersToggle"
        :disabled="isDisabledAndUnoverridable"
        :is-loading="isLoading"
        :label="__('Enable shared runners for this project')"
        :value="isSharedRunnerEnabled"
        data-testid="toggle-shared-runners"
        @change="toggleSharedRunners"
      />

      <gl-tooltip v-if="isDisabledAndUnoverridable" :target="() => $refs.sharedRunnersToggle">
        {{ __('Shared runners are disabled on group level') }}
      </gl-tooltip>
    </section>
  </div>
</template>
