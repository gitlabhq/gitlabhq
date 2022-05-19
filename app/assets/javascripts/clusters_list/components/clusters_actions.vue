<script>
import { GlButton, GlDropdown, GlDropdownItem, GlModalDirective, GlTooltip } from '@gitlab/ui';

import { INSTALL_AGENT_MODAL_ID, CLUSTERS_ACTIONS } from '../constants';

export default {
  i18n: CLUSTERS_ACTIONS,
  INSTALL_AGENT_MODAL_ID,
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlTooltip,
  },
  directives: {
    GlModalDirective,
  },
  inject: [
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
    actionItems() {
      const createCluster = {
        href: this.newClusterDocsPath,
        title: this.$options.i18n.createCluster,
        testid: 'create-cluster-link',
      };
      const connectCluster = {
        href: this.addClusterPath,
        title: this.$options.i18n.connectClusterCertificate,
        testid: 'connect-cluster-link',
      };
      const actions = [];

      if (this.displayClusterAgents) {
        actions.push(createCluster);
      }
      if (this.displayClusterAgents && this.certificateBasedClustersEnabled) {
        actions.push(connectCluster);
      }

      return actions;
    },
  },
  methods: {
    getTooltipTarget() {
      return this.actionItems.length ? this.$refs.actions.$el : this.$refs.actionsContainer;
    },
  },
};
</script>

<template>
  <div ref="actionsContainer" class="nav-controls gl-ml-auto">
    <gl-tooltip
      v-if="!canAddCluster"
      :target="() => getTooltipTarget()"
      :title="$options.i18n.actionsDisabledHint"
    />

    <gl-button
      v-if="!actionItems.length"
      data-qa-selector="clusters_actions_button"
      category="primary"
      variant="confirm"
      :disabled="!canAddCluster"
      :href="defaultActionUrl"
    >
      {{ defaultActionText }}
    </gl-button>

    <gl-dropdown
      v-else
      ref="actions"
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
        v-for="action in actionItems"
        :key="action.title"
        :href="action.href"
        :data-testid="action.testid"
        @click.stop
      >
        {{ action.title }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
