<script>
import {
  GlFormGroup,
  GlFormInput,
  GlToggle,
  GlTooltipDirective,
  GlSprintf,
  GlLink,
  GlButton,
} from '@gitlab/ui';
import { mapState } from 'vuex';
import { s__ } from '~/locale';

export default {
  i18n: {
    toggleLabel: s__(
      "ClusterIntegration|Enable or disable GitLab's connection to your Kubernetes cluster.",
    ),
  },
  components: {
    GlFormGroup,
    GlToggle,
    GlFormInput,
    GlSprintf,
    GlLink,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    autoDevopsHelpPath: {
      default: '',
    },
    externalEndpointHelpPath: {
      default: '',
    },
  },
  data() {
    return {
      toggleEnabled: true,
      envScope: '*',
      baseDomainField: '',
    };
  },
  computed: {
    ...mapState(['enabled', 'editable', 'environmentScope', 'baseDomain']),
    canSubmit() {
      return (
        this.enabled !== this.toggleEnabled ||
        this.environmentScope !== this.envScope ||
        this.baseDomain !== this.baseDomainField
      );
    },
  },
  mounted() {
    this.toggleEnabled = this.enabled;
    this.envScope = this.environmentScope;
    this.baseDomainField = this.baseDomain;
  },
};
</script>

<template>
  <div class="d-flex gl-flex-direction-column">
    <gl-form-group>
      <div class="gl-display-flex gl-align-items-center">
        <h4 class="gl-pr-3 gl-m-0">{{ s__('ClusterIntegration|GitLab Integration') }}</h4>

        <div class="js-cluster-enable-toggle-area">
          <gl-toggle
            id="toggleCluster"
            v-model="toggleEnabled"
            v-gl-tooltip:tooltipcontainer
            name="cluster[enabled]"
            class="gl-mb-0 js-project-feature-toggle"
            data-qa-selector="integration_status_toggle"
            aria-describedby="toggleCluster"
            :disabled="!editable"
            :label="$options.i18n.toggleLabel"
            label-position="hidden"
            :title="$options.i18n.toggleLabel"
          />
        </div>
      </div>
    </gl-form-group>

    <gl-form-group
      :label="s__('ClusterIntegration|Environment scope')"
      label-size="sm"
      label-for="cluster_environment_scope"
      :description="
        s__('ClusterIntegration|Choose which of your environments will use this cluster.')
      "
    >
      <gl-form-input
        id="cluster_environment_scope"
        v-model="envScope"
        name="cluster[environment_scope]"
        class="col-md-6"
        type="text"
      />
    </gl-form-group>

    <gl-form-group
      :label="s__('ClusterIntegration|Base domain')"
      label-size="sm"
      label-for="cluster_base_domain"
    >
      <gl-form-input
        id="cluster_base_domain"
        v-model="baseDomainField"
        name="cluster[base_domain]"
        data-qa-selector="base_domain_field"
        class="col-md-6"
        type="text"
      />
      <div class="form-text text-muted inline">
        <gl-sprintf
          :message="
            s__(
              'ClusterIntegration|Specifying a domain will allow you to use Auto Review Apps and Auto Deploy stages for %{linkStart}Auto DevOps.%{linkEnd} The domain should have a wildcard DNS configured matching the domain. ',
            )
          "
        >
          <template #link="{ content }">
            <gl-link :href="autoDevopsHelpPath" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
        <gl-sprintf
          class="inline"
          :message="s__('ClusterIntegration|%{linkStart}More information%{linkEnd}')"
        >
          <template #link="{ content }">
            <gl-link :href="externalEndpointHelpPath" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </div>
    </gl-form-group>
    <div v-if="editable" class="form group gl-display-flex gl-justify-content-end">
      <gl-button
        category="primary"
        variant="success"
        type="submit"
        :disabled="!canSubmit"
        :aria-disabled="!canSubmit"
        data-qa-selector="save_changes_button"
        >{{ s__('ClusterIntegration|Save changes') }}</gl-button
      >
    </div>
  </div>
</template>
