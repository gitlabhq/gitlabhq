<script>
import { GlFormGroup, GlToggle, GlTooltipDirective } from '@gitlab/ui';
import { mapState } from 'vuex';

export default {
  components: {
    GlFormGroup,
    GlToggle,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  data() {
    return {
      toggleEnabled: true,
    };
  },
  computed: {
    ...mapState(['enabled', 'editable']),
  },
  mounted() {
    this.toggleEnabled = this.enabled;
  },
};
</script>

<template>
  <div class="d-flex align-items-center">
    <gl-form-group>
      <div class="gl-display-flex gl-align-items-center">
        <h4 class="gl-pr-3 gl-m-0 ">{{ s__('ClusterIntegration|GitLab Integration') }}</h4>
        <input
          id="cluster_enabled"
          class="js-project-feature-toggle-input"
          type="hidden"
          :value="toggleEnabled"
          name="cluster[enabled]"
        />
        <div id="tooltipcontainer" class="js-cluster-enable-toggle-area">
          <gl-toggle
            v-model="toggleEnabled"
            v-gl-tooltip:tooltipcontainer
            class="gl-mb-0 js-project-feature-toggle"
            data-qa-selector="integration_status_toggle"
            :aria-describedby="__('Toggle Kubernetes cluster')"
            :disabled="!editable"
            :is_checked="toggleEnabled"
            :title="
              s__(
                'ClusterIntegration|Enable or disable GitLab\'s connection to your Kubernetes cluster.',
              )
            "
          />
        </div>
      </div>
    </gl-form-group>
  </div>
</template>
