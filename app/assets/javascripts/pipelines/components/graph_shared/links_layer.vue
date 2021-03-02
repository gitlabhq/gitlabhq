<script>
import { GlAlert } from '@gitlab/ui';
import { __ } from '~/locale';
import { reportToSentry } from '../graph/utils';
import LinksInner from './links_inner.vue';

export default {
  name: 'LinksLayer',
  components: {
    GlAlert,
    LinksInner,
  },
  MAX_GROUPS: 200,
  props: {
    containerMeasurements: {
      type: Object,
      required: true,
    },
    pipelineData: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      alertDismissed: false,
      showLinksOverride: false,
    };
  },
  i18n: {
    showLinksAnyways: __('Show links anyways'),
    tooManyJobs: __(
      'This graph has a large number of jobs and showing the links between them may have performance implications.',
    ),
  },
  computed: {
    containerZero() {
      return !this.containerMeasurements.width || !this.containerMeasurements.height;
    },
    numGroups() {
      return this.pipelineData.reduce((acc, { groups }) => {
        return acc + Number(groups.length);
      }, 0);
    },
    showAlert() {
      return !this.containerZero && !this.showLinkedLayers && !this.alertDismissed;
    },
    showLinkedLayers() {
      return (
        !this.containerZero && (this.showLinksOverride || this.numGroups < this.$options.MAX_GROUPS)
      );
    },
  },
  errorCaptured(err, _vm, info) {
    reportToSentry(this.$options.name, `error: ${err}, info: ${info}`);
  },
  methods: {
    dismissAlert() {
      this.alertDismissed = true;
    },
    overrideShowLinks() {
      this.dismissAlert();
      this.showLinksOverride = true;
    },
  },
};
</script>
<template>
  <links-inner
    v-if="showLinkedLayers"
    :container-measurements="containerMeasurements"
    :pipeline-data="pipelineData"
    :total-groups="numGroups"
    v-bind="$attrs"
    v-on="$listeners"
  >
    <slot></slot>
  </links-inner>
  <div v-else>
    <gl-alert
      v-if="showAlert"
      class="gl-ml-4 gl-mb-4"
      :primary-button-text="$options.i18n.showLinksAnyways"
      @primaryAction="overrideShowLinks"
      @dismiss="dismissAlert"
    >
      {{ $options.i18n.tooManyJobs }}
    </gl-alert>
    <div class="gl-display-flex gl-relative">
      <slot></slot>
    </div>
  </div>
</template>
