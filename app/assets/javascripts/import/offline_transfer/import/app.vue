<script>
import { GlAlert, GlFormCheckbox } from '@gitlab/ui';
import FormStepper from '~/import/offline_transfer/components/form_stepper.vue';
import { OFFLINE_IMPORT_TAB_HEADINGS } from '../constants';

export default {
  name: 'OfflineTransferImportApp',
  components: {
    FormStepper,
    GlAlert,
    GlFormCheckbox,
  },
  data() {
    return {
      isConfigComplete: false,
      isReviewComplete: false,
      hasSubmitSucceeded: false,
    };
  },
  methods: {
    validateStep(stepIndex) {
      switch (stepIndex) {
        case 0:
          return this.isConfigComplete;
        case 1:
          return this.isReviewComplete;
        default:
          return false;
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
    >
      <template #step-0>
        <div data-testid="configure-tab">
          <gl-form-checkbox v-model="isConfigComplete">
            {{ s__('OfflineTransferImport|Select destination') }}
          </gl-form-checkbox>
        </div>
      </template>
      <template #step-1>
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
