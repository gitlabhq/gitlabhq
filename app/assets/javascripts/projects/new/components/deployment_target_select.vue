<script>
import { GlFormGroup, GlFormSelect, GlSprintf, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import {
  DEPLOYMENT_TARGET_SELECTIONS,
  DEPLOYMENT_TARGET_LABEL,
  DEPLOYMENT_TARGET_EVENT,
  VISIT_DOCS_EVENT,
  NEW_PROJECT_FORM,
  K8S_OPTION,
} from '../constants';

const trackingMixin = Tracking.mixin({ label: DEPLOYMENT_TARGET_LABEL });

export default {
  i18n: {
    deploymentTargetLabel: s__('Deployment Target|Project deployment target (optional)'),
    defaultOption: s__('Deployment Target|Select the deployment target'),
    k8sEducationText: s__(
      'Deployment Target|%{linkStart}How to provision or deploy to Kubernetes clusters from GitLab?%{linkEnd}',
    ),
  },
  deploymentTargets: DEPLOYMENT_TARGET_SELECTIONS,
  VISIT_DOCS_EVENT,
  DEPLOYMENT_TARGET_LABEL,
  selectId: 'deployment-target-select',
  helpPageUrl: helpPagePath('user/clusters/agent/_index'),
  components: {
    GlFormGroup,
    GlFormSelect,
    GlSprintf,
    GlLink,
  },
  mixins: [trackingMixin],
  data() {
    return {
      selectedTarget: null,
      formSubmitted: false,
    };
  },
  computed: {
    isK8sOptionSelected() {
      return this.selectedTarget === K8S_OPTION.value;
    },
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
      class="input-lg"
    >
      <template #first>
        <option :value="null" disabled>{{ $options.i18n.defaultOption }}</option>
      </template>
    </gl-form-select>

    <template v-if="isK8sOptionSelected" #description>
      <gl-sprintf :message="$options.i18n.k8sEducationText">
        <template #link="{ content }">
          <gl-link
            :href="$options.helpPageUrl"
            :data-track-action="$options.VISIT_DOCS_EVENT"
            :data-track-label="$options.DEPLOYMENT_TARGET_LABEL"
            >{{ content }}</gl-link
          >
        </template>
      </gl-sprintf>
    </template>
  </gl-form-group>
</template>
