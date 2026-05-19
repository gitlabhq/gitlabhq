<script>
import { GlAlert, GlFormCheckbox } from '@gitlab/ui';
import FormStepper from '~/import/offline_transfer/components/form_stepper.vue';
import { OFFLINE_EXPORT_STEPS } from '../constants';

export default {
  name: 'OfflineTransferExportApp',
  components: {
    FormStepper,
    GlAlert,
    GlFormCheckbox,
  },
  data() {
    return {
      steps: OFFLINE_EXPORT_STEPS,
      showValidationError: false,
      isComplete: false,
      // TODO: will update when building form
      formData: {
        select: false,
        configure: false,
        review: false,
        export: false,
      },
    };
  },

  methods: {
    onComplete() {
      this.isComplete = true;
    },
    onValidationFailed() {
      this.showValidationError = true;
    },
    validateStep(stepIndex) {
      switch (stepIndex) {
        case 0:
          return this.formData.select;
        case 1:
          return this.formData.configure;
        case 2:
          return this.formData.review;
        case 3:
          return this.formData.export;
        default:
          return false;
      }
    },
    onStepChanged({ previousTabIndex }) {
      const fields = ['select', 'configure', 'review', 'export'];
      this.formData[fields[previousTabIndex]] = false;
    },
  },
};
</script>

<template>
  <div>
    <header class="gl-my-5">
      <h1 class="gl-heading-display">
        {{ s__('OfflineTransferExport|Export for offline transfer') }}
      </h1>
      <p class="gl-max-w-2xl">
        {{
          s__(
            'OfflineTransferExport|Export your groups and projects to an object storage service you control. You can import the groups and projects to any GitLab instance, even with no network connection between this instance and the destination instance.',
          )
        }}
      </p>
      <!-- // temporary alerts, to be replaced-->
      <gl-alert
        v-if="isComplete"
        :title="__('Complete')"
        :dismiss-label="__('Dismiss')"
        dismissible
        variant="info"
        data-testid="completion-alert"
        @dismiss="isComplete = false"
      />
      <gl-alert
        v-if="showValidationError"
        :title="__('Error')"
        :dismiss-label="__('Dismiss')"
        dismissible
        variant="danger"
        data-testid="validation-alert"
        @dismiss="showValidationError = false"
      />
    </header>

    <form-stepper
      :steps="steps"
      :validate-step="validateStep"
      :completion-button-text="s__('OfflineTransfer|Start export')"
      @stepped-back="onStepChanged"
      @validation-failed="onValidationFailed"
      @complete="onComplete"
    >
      <template #step-0>
        <h2 class="gl-heading-3">
          {{ s__('OfflineTransfer|Select groups and projects to export') }}
        </h2>
        <gl-form-checkbox v-model="formData.select" />
      </template>

      <template #step-1>
        <h2 class="gl-heading-3">{{ s__('OfflineTransfer|Export configuration') }}</h2>
        <gl-form-checkbox v-model="formData.configure" />
      </template>

      <template #step-2>
        <h2 class="gl-heading-3">{{ s__('OfflineTransfer|Review export') }}</h2>
        <gl-form-checkbox v-model="formData.review" />
      </template>

      <template #step-3>
        <h2 class="gl-heading-3">{{ s__('OfflineTransfer|Export') }}</h2>
        <gl-form-checkbox v-model="formData.export" />
      </template>
    </form-stepper>
  </div>
</template>
