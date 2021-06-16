<script>
import { GlButton, GlLink } from '@gitlab/ui';
import { mapState } from 'vuex';
import { s__ } from '../../locale';

export default {
  components: {
    GlButton,
    GlLink,
  },
  props: {
    missingData: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapState(['clustersPath', 'helpPath']),
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
            `ServerlessDetails|Function invocation metrics require the Prometheus cluster integration.`,
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
          <gl-button :href="clustersPath" variant="success" category="primary">
            {{ s__('ServerlessDetails|Configure cluster.') }}
          </gl-button>
        </div>
      </div>
    </div>
  </div>
</template>
