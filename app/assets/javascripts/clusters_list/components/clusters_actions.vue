<script>
import {
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlModalDirective,
  GlTooltipDirective,
  GlDropdownDivider,
  GlDropdownSectionHeader,
} from '@gitlab/ui';

import { INSTALL_AGENT_MODAL_ID, CLUSTERS_ACTIONS } from '../constants';

export default {
  i18n: CLUSTERS_ACTIONS,
  INSTALL_AGENT_MODAL_ID,
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlDropdownSectionHeader,
  },
  directives: {
    GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  inject: [
    'newClusterPath',
    'addClusterPath',
    'canAddCluster',
    'displayClusterAgents',
    'certificateBasedClustersEnabled',
  ],
  computed: {
    tooltip() {
      const { connectWithAgent, connectExistingCluster, dropdownDisabledHint } = this.$options.i18n;

      if (!this.canAddCluster) {
        return dropdownDisabledHint;
      } else if (this.displayClusterAgents) {
        return connectWithAgent;
      }

      return connectExistingCluster;
    },
    shouldTriggerModal() {
      return this.canAddCluster && this.displayClusterAgents;
    },
  },
};
</script>

<template>
  <div class="nav-controls gl-ml-auto">
    <gl-dropdown
      v-if="certificateBasedClustersEnabled"
      ref="dropdown"
      v-gl-modal-directive="shouldTriggerModal && $options.INSTALL_AGENT_MODAL_ID"
      v-gl-tooltip="tooltip"
      category="primary"
      variant="confirm"
      :text="$options.i18n.actionsButton"
      :disabled="!canAddCluster"
      :split="displayClusterAgents"
      right
    >
      <template v-if="displayClusterAgents">
        <gl-dropdown-section-header>{{ $options.i18n.agent }}</gl-dropdown-section-header>
        <gl-dropdown-item
          v-gl-modal-directive="$options.INSTALL_AGENT_MODAL_ID"
          data-testid="connect-new-agent-link"
        >
          {{ $options.i18n.connectWithAgent }}
        </gl-dropdown-item>
        <gl-dropdown-divider />
        <gl-dropdown-section-header>{{ $options.i18n.certificate }}</gl-dropdown-section-header>
      </template>

      <gl-dropdown-item :href="newClusterPath" data-testid="new-cluster-link" @click.stop>
        {{ $options.i18n.createNewCluster }}
      </gl-dropdown-item>
      <gl-dropdown-item :href="addClusterPath" data-testid="connect-cluster-link" @click.stop>
        {{ $options.i18n.connectExistingCluster }}
      </gl-dropdown-item>
    </gl-dropdown>
    <gl-button
      v-else
      v-gl-modal-directive="$options.INSTALL_AGENT_MODAL_ID"
      v-gl-tooltip="tooltip"
      :disabled="!canAddCluster"
      category="primary"
      variant="confirm"
    >
      {{ $options.i18n.connectWithAgent }}
    </gl-button>
  </div>
</template>
