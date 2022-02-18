<script>
import { GlFormGroup, GlFormSelect } from '@gitlab/ui';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import {
  DEPLOYMENT_TARGET_SELECTIONS,
  DEPLOYMENT_TARGET_LABEL,
  DEPLOYMENT_TARGET_EVENT,
  NEW_PROJECT_FORM,
} from '../constants';

const trackingMixin = Tracking.mixin({ label: DEPLOYMENT_TARGET_LABEL });

export default {
  i18n: {
    deploymentTargetLabel: s__('Deployment Target|Project deployment target (optional)'),
    defaultOption: s__('Deployment Target|Select the deployment target'),
  },
  deploymentTargets: DEPLOYMENT_TARGET_SELECTIONS,
  selectId: 'deployment-target-select',
  components: {
    GlFormGroup,
    GlFormSelect,
  },
  mixins: [trackingMixin],
  data() {
    return {
      selectedTarget: null,
      formSubmitted: false,
    };
  },
  mounted() {
    const form = document.getElementById(NEW_PROJECT_FORM);
    form.addEventListener('submit', () => {
      this.formSubmitted = true;
      this.trackSelection();
    });
  },
  methods: {
    trackSelection() {
      if (this.formSubmitted && this.selectedTarget) {
        this.track(DEPLOYMENT_TARGET_EVENT, { property: this.selectedTarget });
      }
    },
  },
};
</script>

<template>
  <gl-form-group :label="$options.i18n.deploymentTargetLabel" :label-for="$options.selectId">
    <gl-form-select
      :id="$options.selectId"
      v-model="selectedTarget"
      :options="$options.deploymentTargets"
    >
      <template #first>
        <option :value="null" disabled>{{ $options.i18n.defaultOption }}</option>
      </template>
    </gl-form-select>
  </gl-form-group>
</template>
