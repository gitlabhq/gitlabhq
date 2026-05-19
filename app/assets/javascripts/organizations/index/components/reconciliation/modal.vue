<script>
import { GlButton, GlModal, GlSprintf } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { createAlert } from '~/alert';
import { isDefaultOrganization } from '~/organizations/shared/utils';
import organizationsForReconciliationQuery from '~/organizations/index/graphql/queries/organizations_for_reconciliation.query.graphql';
import SkeletonLoader from './skeleton_loader.vue';
import Step1 from './steps/step_1.vue';
import Step2 from './steps/step_2.vue';
import Step3 from './steps/step_3.vue';

export default {
  name: 'OrganizationReconciliationModal',
  i18n: {
    stepProgress: s__('Organization|Step %{currentStep} / %{totalSteps}'),
    errorMessage: s__('Organization|An error occurred fetching organizations. Please try again.'),
  },
  components: {
    GlButton,
    GlModal,
    GlSprintf,
    SkeletonLoader,
  },
  stepComponents: [Step1, Step2, Step3],
  model: {
    prop: 'visible',
    event: 'change',
  },
  props: {
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['change'],
  data() {
    return {
      currentStep: 1,
      organizations: [],
    };
  },
  apollo: {
    organizations: {
      query: organizationsForReconciliationQuery,
      skip() {
        return !this.visible || this.organizations.length > 0;
      },
      update(data) {
        return data?.organizations?.nodes || [];
      },
      error(error) {
        createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
      },
    },
  },
  computed: {
    loading() {
      return this.$apollo.queries.organizations.loading;
    },
    organizationsWithoutDefault() {
      return this.organizations.filter((org) => !isDefaultOrganization(org));
    },
    stepOrganizations() {
      if (this.currentStep === 2) {
        return this.organizations;
      }

      return this.organizationsWithoutDefault;
    },
    stepComponent() {
      return this.$options.stepComponents[this.currentStep - 1];
    },
    totalSteps() {
      return this.$options.stepComponents.length;
    },
    isFirstStep() {
      return this.currentStep === 1;
    },
    isLastStep() {
      return this.currentStep === this.totalSteps;
    },
    prevButtonText() {
      return this.isFirstStep ? __('Cancel') : __('Back');
    },
    nextButtonText() {
      return this.isLastStep ? __('Confirm') : __('Continue');
    },
  },
  methods: {
    updateModalVisibility(value) {
      this.$emit('change', value);
    },
    onNext() {
      if (!this.isLastStep) {
        this.currentStep += 1;
      }

      // TODO: Hook up API to complete reconciliation here https://gitlab.com/gitlab-org/gitlab/-/work_items/596669
    },
    onPrev() {
      if (this.isFirstStep) {
        this.updateModalVisibility(false);
      } else {
        this.currentStep -= 1;
      }
    },
    onUpdate(updatedOrganizations) {
      this.organizations = updatedOrganizations;
    },
  },
};
</script>

<template>
  <gl-modal
    modal-id="organization-reconciliation-modal"
    scrollable
    :visible="visible"
    :hide-footer="loading"
    @change="updateModalVisibility($event)"
  >
    <skeleton-loader v-if="loading" />
    <template v-if="!loading">
      <div class="gl-text-center gl-font-bold">
        <gl-sprintf :message="$options.i18n.stepProgress">
          <template #currentStep>{{ currentStep }}</template>
          <template #totalSteps>{{ totalSteps }}</template>
        </gl-sprintf>
      </div>
      <component :is="stepComponent" :organizations="stepOrganizations" @update="onUpdate" />
    </template>
    <template #modal-footer>
      <div class="gl-flex gl-w-full gl-justify-center gl-gap-3">
        <gl-button @click="onPrev">{{ prevButtonText }}</gl-button>
        <gl-button variant="confirm" @click="onNext">{{ nextButtonText }}</gl-button>
      </div>
    </template>
  </gl-modal>
</template>
