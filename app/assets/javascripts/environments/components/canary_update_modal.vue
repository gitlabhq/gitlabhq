<script>
import { GlAlert, GlModal, GlSprintf } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { CANARY_UPDATE_MODAL } from '../constants';
import updateCanaryIngress from '../graphql/mutations/update_canary_ingress.mutation.graphql';

export default {
  components: {
    GlAlert,
    GlModal,
    GlSprintf,
  },
  props: {
    environment: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    weight: {
      type: Number,
      required: false,
      default: 0,
    },
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  translations: {
    title: s__('CanaryIngress|Change the ratio of canary deployments?'),
    ratioChange: s__(
      'CanaryIngress|You are changing the ratio of the canary rollout for %{environment} compared to the stable deployment to:',
    ),
    stableWeight: s__('CanaryIngress|%{boldStart}Stable:%{boldEnd} %{stable}'),
    canaryWeight: s__('CanaryIngress|%{boldStart}Canary:%{boldEnd} %{canary}'),
    deploymentWarning: s__(
      'CanaryIngress|Doing so will set a deployment change in progress. This temporarily blocks any further configuration until the deployment is finished.',
    ),
  },
  modal: {
    modalId: CANARY_UPDATE_MODAL,
    actionPrimary: {
      text: s__('CanaryIngress|Change ratio'),
      attributes: { variant: 'confirm' },
    },
    actionCancel: { text: __('Cancel') },
    static: true,
  },
  data() {
    return { error: '', dismissed: true };
  },
  computed: {
    stableWeight() {
      return (100 - this.weight).toString();
    },
    canaryWeight() {
      return this.weight.toString();
    },
    hasError() {
      return Boolean(this.error);
    },
    environmentName() {
      return this.environment?.name ?? '';
    },
  },
  methods: {
    submitCanaryChange() {
      return this.$apollo
        .mutate({
          mutation: updateCanaryIngress,
          variables: {
            input: {
              id: this.environment.global_id || this.environment.globalId,
              weight: this.weight,
            },
          },
        })
        .then(
          ({
            data: {
              environmentsCanaryIngressUpdate: {
                errors: [error],
              },
            },
          }) => {
            this.error = error;
          },
        )
        .catch(() => {
          this.error = __('Something went wrong. Please try again later');
        });
    },
    dismiss() {
      this.error = '';
    },
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="hasError" variant="danger" @dismiss="dismiss">{{ error }}</gl-alert>
    <gl-modal v-bind="$options.modal" :visible="visible" @primary="submitCanaryChange">
      <template #modal-title>{{ $options.translations.title }}</template>
      <template #default>
        <p>
          <gl-sprintf :message="$options.translations.ratioChange">
            <template #environment>{{ environmentName }}</template>
          </gl-sprintf>
        </p>
        <ul class="gl-list-none gl-p-0">
          <li>
            <gl-sprintf :message="$options.translations.stableWeight">
              <template #bold="{ content }">
                <span class="gl-font-bold">{{ content }}</span>
              </template>
              <template #stable>{{ stableWeight }}</template>
            </gl-sprintf>
          </li>
          <li>
            <gl-sprintf :message="$options.translations.canaryWeight">
              <template #bold="{ content }">
                <span class="gl-font-bold">{{ content }}</span>
              </template>
              <template #canary>{{ canaryWeight }}</template>
            </gl-sprintf>
          </li>
        </ul>
        <p>{{ $options.translations.deploymentWarning }}</p>
      </template>
    </gl-modal>
  </div>
</template>
