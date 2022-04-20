<script>
import { GlDropdown, GlDropdownItem, GlModalDirective, GlTooltip } from '@gitlab/ui';

import { INSTALL_AGENT_MODAL_ID, CLUSTERS_ACTIONS } from '../constants';

export default {
  i18n: CLUSTERS_ACTIONS,
  INSTALL_AGENT_MODAL_ID,
  components: {
    GlDropdown,
    GlDropdownItem,
    GlTooltip,
  },
  directives: {
    GlModalDirective,
  },
  inject: [
    'newClusterPath',
    'addClusterPath',
    'newClusterDocsPath',
    'canAddCluster',
    'displayClusterAgents',
    'certificateBasedClustersEnabled',
  ],
  computed: {
    shouldTriggerModal() {
      return this.canAddCluster && this.displayClusterAgents;
    },
    defaultActionText() {
      const { connectCluster, connectWithAgent, connectClusterDeprecated } = this.$options.i18n;

      if (!this.displayClusterAgents) {
        return connectClusterDeprecated;
      } else if (!this.certificateBasedClustersEnabled) {
        return connectCluster;
      }
      return connectWithAgent;
    },
    defaultActionUrl() {
      if (this.displayClusterAgents) {
        return null;
      }
      return this.addClusterPath;
    },
  },
};
</script>

<template>
  <div class="nav-controls gl-ml-auto">
    <gl-tooltip
      v-if="!canAddCluster"
      :target="() => $refs.dropdown.$el"
      :title="$options.i18n.dropdownDisabledHint"
    />

    <gl-dropdown
      ref="dropdown"
      v-gl-modal-directive="shouldTriggerModal && $options.INSTALL_AGENT_MODAL_ID"
      data-qa-selector="clusters_actions_button"
      category="primary"
      variant="confirm"
      :text="defaultActionText"
      :disabled="!canAddCluster"
      :split-href="defaultActionUrl"
      split
      right
    >
      <gl-dropdown-item
        v-if="displayClusterAgents"
        :href="newClusterDocsPath"
        data-testid="create-cluster-link"
        @click.stop
      >
        {{ $options.i18n.createCluster }}
      </gl-dropdown-item>

      <template v-if="displayClusterAgents && certificateBasedClustersEnabled">
        <gl-dropdown-item :href="newClusterPath" data-testid="new-cluster-link" @click.stop>
          {{ $options.i18n.createClusterCertificate }}
        </gl-dropdown-item>

        <gl-dropdown-item :href="addClusterPath" data-testid="connect-cluster-link" @click.stop>
          {{ $options.i18n.connectClusterCertificate }}
        </gl-dropdown-item>
      </template>

      <gl-dropdown-item
        v-if="certificateBasedClustersEnabled && !displayClusterAgents"
        :href="newClusterPath"
        data-testid="new-cluster-link"
        @click.stop
      >
        {{ $options.i18n.createClusterDeprecated }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
