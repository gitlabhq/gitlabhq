<script>
import { GlDropdown, GlDropdownItem, GlModalDirective, GlTooltipDirective } from '@gitlab/ui';
import { INSTALL_AGENT_MODAL_ID, CLUSTERS_ACTIONS } from '../constants';

export default {
  i18n: CLUSTERS_ACTIONS,
  INSTALL_AGENT_MODAL_ID,
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  directives: {
    GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  inject: ['newClusterPath', 'addClusterPath', 'canAddCluster'],
  computed: {
    tooltip() {
      const { connectWithAgent, dropdownDisabledHint } = this.$options.i18n;
      return this.canAddCluster ? connectWithAgent : dropdownDisabledHint;
    },
  },
};
</script>

<template>
  <div class="nav-controls gl-ml-auto">
    <gl-dropdown
      ref="dropdown"
      v-gl-modal-directive="canAddCluster && $options.INSTALL_AGENT_MODAL_ID"
      v-gl-tooltip="tooltip"
      category="primary"
      variant="confirm"
      :text="$options.i18n.actionsButton"
      :disabled="!canAddCluster"
      split
      right
    >
      <gl-dropdown-item :href="newClusterPath" data-testid="new-cluster-link" @click.stop>
        {{ $options.i18n.createNewCluster }}
      </gl-dropdown-item>
      <gl-dropdown-item
        v-gl-modal-directive="$options.INSTALL_AGENT_MODAL_ID"
        data-testid="connect-new-agent-link"
      >
        {{ $options.i18n.connectWithAgent }}
      </gl-dropdown-item>
      <gl-dropdown-item :href="addClusterPath" data-testid="connect-cluster-link" @click.stop>
        {{ $options.i18n.connectExistingCluster }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
