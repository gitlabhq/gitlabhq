<script>
import { GlButton, GlLink } from '@gitlab/ui';
import { s__ } from '../../locale';

export default {
  components: {
    GlButton,
    GlLink,
  },
  props: {
    clustersPath: {
      type: String,
      required: true,
    },
    helpPath: {
      type: String,
      required: true,
    },
    missingData: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    missingStateClass() {
      return this.missingData ? 'missing-prometheus-state' : 'empty-prometheus-state';
    },
    prometheusHelpPath() {
      return `${this.helpPath}#prometheus-support`;
    },
    description() {
      return this.missingData
        ? s__(`ServerlessDetails|Invocation metrics loading or not available at this time.`)
        : s__(
            `ServerlessDetails|Function invocation metrics require Prometheus to be installed first.`,
          );
    },
  },
};
</script>

<template>
  <div class="row" :class="missingStateClass">
    <div class="col-12">
      <div class="text-content">
        <h4 class="state-title text-left">{{ s__(`ServerlessDetails|Invocations`) }}</h4>
        <p class="state-description">
          {{ description }}
          <gl-link :href="prometheusHelpPath">{{
            s__(`ServerlessDetails|More information`)
          }}</gl-link
          >.
        </p>

        <div v-if="!missingData" class="text-left">
          <gl-button :href="clustersPath" variant="success">
            {{ s__('ServerlessDetails|Install Prometheus') }}
          </gl-button>
        </div>
      </div>
    </div>
  </div>
</template>
