<script>
import {
  GlButton,
  GlButtonGroup,
  GlModalDirective,
  GlTooltip,
  GlDisclosureDropdown,
} from '@gitlab/ui';

import { INSTALL_AGENT_MODAL_ID, CLUSTERS_ACTIONS } from '../constants';

export default {
  i18n: CLUSTERS_ACTIONS,
  INSTALL_AGENT_MODAL_ID,
  components: {
    GlButton,
    GlButtonGroup,
    GlDisclosureDropdown,
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
      }
      if (!this.certificateBasedClustersEnabled) {
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
        text: this.$options.i18n.createCluster,
        extraAttrs: {
          'data-testid': 'create-cluster-link',
        },
      };
      const connectCluster = {
        href: this.addClusterPath,
        text: this.$options.i18n.connectClusterCertificate,
        extraAttrs: {
          'data-testid': 'connect-cluster-link',
        },
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

    <gl-button-group ref="actions" class="gl-mb-3 gl-w-full md:gl-mb-0 md:gl-w-auto">
      <gl-button
        v-gl-modal-directive="shouldTriggerModal && $options.INSTALL_AGENT_MODAL_ID"
        :href="defaultActionUrl"
        :disabled="!canAddCluster"
        data-testid="clusters-default-action-button"
        category="primary"
        variant="confirm"
      >
        {{ defaultActionText }}
      </gl-button>
      <gl-disclosure-dropdown
        v-if="actionItems.length"
        category="primary"
        variant="confirm"
        placement="bottom-end"
        :toggle-text="defaultActionText"
        :items="actionItems"
        :disabled="!canAddCluster"
        text-sr-only
      />
    </gl-button-group>
  </div>
</template>
