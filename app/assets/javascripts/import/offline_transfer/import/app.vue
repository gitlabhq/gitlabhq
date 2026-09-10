<script>
import { GlAlert, GlFormCheckbox } from '@gitlab/ui';
import FormStepper from '~/import/offline_transfer/components/form_stepper.vue';
import SelectDestinationTab from '~/import/offline_transfer/import/select_destination_tab.vue';
import { OFFLINE_IMPORT_TAB_HEADINGS, DESTINATION_TOP_LEVEL } from '../constants';

export default {
  name: 'OfflineTransferImportApp',
  components: {
    FormStepper,
    GlAlert,
    GlFormCheckbox,
    SelectDestinationTab,
  },
  data() {
    return {
      destinationSelection: {
        type: DESTINATION_TOP_LEVEL,
        parentGroup: null,
      },
      isConfigureComplete: false,
      showDestinationError: false,
      isReviewComplete: false,
      hasSubmitSucceeded: false,
    };
  },
  computed: {
    isDestinationValid() {
      return (
        this.destinationSelection.type === DESTINATION_TOP_LEVEL ||
        Boolean(this.destinationSelection.parentGroup)
      );
    },
  },
  methods: {
    validateStep(stepIndex) {
      switch (stepIndex) {
        case 0:
          return this.isDestinationValid;
        case 1:
          return this.isConfigureComplete;
        case 2:
          return this.isReviewComplete;
        default:
          return false;
      }
    },
    onValidationFailed(stepIndex) {
      if (stepIndex === 0) {
        this.showDestinationError = true;
      }
    },
    onStepChanged({ previousTabIndex }) {
      if (previousTabIndex === 0) {
        this.showDestinationError = false;
      }
    },
    submitForm() {
      this.hasSubmitSucceeded = true;
    },
  },
  STEPS: OFFLINE_IMPORT_TAB_HEADINGS,
};
</script>

<template>
  <div>
    <gl-alert
      v-if="hasSubmitSucceeded"
      :title="__('Complete')"
      :dismiss-label="__('Dismiss')"
      dismissible
      variant="info"
      data-testid="completion-alert"
      @dismiss="hasSubmitSucceeded = false"
    />

    <header class="gl-my-5">
      <h1 class="gl-heading-display">
        {{ s__('OfflineTransferImport|Import for offline transfer') }}
      </h1>
      <p class="gl-max-w-2xl" data-testid="offline-import-subheading">
        {{
          s__(
            'OfflineTransferImport|Import your exported groups from an AWS S3 storage service you control. Each group is imported with all of its subgroups and projects.',
          )
        }}
      </p>
    </header>

    <form-stepper
      :steps="$options.STEPS"
      :validate-step="validateStep"
      :completion-button-text="s__('OfflineTransferImport|Start import')"
      :is-form-complete="hasSubmitSucceeded"
      @complete="submitForm"
      @validation-failed="onValidationFailed"
      @stepped-back="onStepChanged"
      @stepped-forward="onStepChanged"
    >
      <template #step-0>
        <select-destination-tab
          :destination-selection="destinationSelection"
          :validation-attempted="showDestinationError"
          @destination-input="destinationSelection = $event"
        />
      </template>
      <template #step-1>
        <div data-testid="configure-import-tab">
          <h2 class="gl-heading-3">{{ s__('OfflineTransferImport|Enter AWS credentials') }}</h2>
          <gl-form-checkbox v-model="isConfigureComplete">
            {{ __('Configure') }}
          </gl-form-checkbox>
        </div>
      </template>
      <template #step-2>
        <div data-testid="review-import-tab">
          <h2 v-if="hasSubmitSucceeded" class="gl-heading-3">
            {{ s__('OfflineTransferImport|Import has started.') }}
          </h2>
          <gl-form-checkbox v-else v-model="isReviewComplete">
            {{ s__('OfflineTransferImport|Review and import') }}
          </gl-form-checkbox>
        </div>
      </template>
    </form-stepper>
  </div>
</template>
