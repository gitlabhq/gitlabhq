<script>
import { s__ } from '~/locale';
import icon from '~/vue_shared/components/icon.vue';
import loadingIcon from '~/vue_shared/components/loading_icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';

import eventHub from '../event_hub';

import geoNodeActions from './geo_node_actions.vue';
import geoNodeDetails from './geo_node_details.vue';

export default {
  components: {
    icon,
    loadingIcon,
    geoNodeActions,
    geoNodeDetails,
  },
  directives: {
    tooltip,
  },
  props: {
    node: {
      type: Object,
      required: true,
    },
    primaryNode: {
      type: Boolean,
      required: true,
    },
    nodeActionsAllowed: {
      type: Boolean,
      required: true,
    },
    nodeEditAllowed: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      isNodeDetailsLoading: true,
      isNodeDetailsFailed: false,
      nodeHealthStatus: '',
      errorMessage: '',
      nodeDetails: {},
    };
  },
  computed: {
    isNodeNonHTTPS() {
      return this.node.url.startsWith('http://');
    },
    showNodeStatusIcon() {
      if (this.isNodeDetailsLoading) {
        return false;
      }

      return this.isNodeNonHTTPS || this.isNodeDetailsFailed;
    },
    showNodeDetails() {
      if (!this.isNodeDetailsLoading) {
        return !this.isNodeDetailsFailed;
      }
      return false;
    },
    nodeStatusIconClass() {
      const iconClasses = 'prepend-left-10 pull-left';
      if (this.isNodeDetailsFailed) {
        return `${iconClasses} node-status-icon-failure`;
      }
      return `${iconClasses} node-status-icon-warning`;
    },
    nodeStatusIconName() {
      if (this.isNodeDetailsFailed) {
        return 'status_failed_borderless';
      }
      return 'warning';
    },
    nodeStatusIconTooltip() {
      if (this.isNodeDetailsFailed) {
        return '';
      }
      return s__('GeoNodes|You have configured Geo nodes using an insecure HTTP connection. We recommend the use of HTTPS.');
    },
  },
  created() {
    eventHub.$on('nodeDetailsLoaded', this.handleNodeDetails);
    eventHub.$on('nodeDetailsLoadFailed', this.handleNodeDetailsFailure);
  },
  mounted() {
    this.handleMounted();
  },
  beforeDestroy() {
    eventHub.$off('nodeDetailsLoaded', this.handleNodeDetails);
    eventHub.$off('nodeDetailsLoadFailed', this.handleNodeDetailsFailure);
  },
  methods: {
    handleNodeDetails(nodeDetails) {
      if (this.node.id === nodeDetails.id) {
        this.isNodeDetailsLoading = false;
        this.isNodeDetailsFailed = false;
        this.errorMessage = '';
        this.nodeDetails = nodeDetails;
        this.nodeHealthStatus = nodeDetails.health;
      }
    },
    handleNodeDetailsFailure(nodeId, err) {
      if (this.node.id === nodeId) {
        this.isNodeDetailsLoading = false;
        this.isNodeDetailsFailed = true;
        this.errorMessage = err.message;
      }
    },
    handleMounted() {
      eventHub.$emit('pollNodeDetails', this.node);
    },
  },
};
</script>

<template>
  <li
    :class="{ 'node-action-active': node.nodeActionActive }"
  >
    <div class="row">
      <div class="col-md-8">
        <div class="row">
          <div class="col-md-8 clearfix">
            <strong class="node-url inline pull-left">
              {{ node.url }}
            </strong>
            <loading-icon
              v-if="isNodeDetailsLoading || node.nodeActionActive"
              class="node-details-loading prepend-left-10 pull-left inline"
              size="1"
            />
            <icon
              v-tooltip
              v-if="showNodeStatusIcon"
              data-container="body"
              data-placement="bottom"
              :name="nodeStatusIconName"
              :size="18"
              :css-classes="nodeStatusIconClass"
              :title="nodeStatusIconTooltip"
            />
            <span class="inline pull-left prepend-left-10">
              <span
                class="node-badge current-node"
                v-if="node.current"
              >
                {{ s__('Current node') }}
              </span>
              <span
                class="node-badge primary-node"
                v-if="node.primary"
              >
                {{ s__('Primary') }}
              </span>
            </span>
          </div>
        </div>
      </div>
      <geo-node-actions
        v-if="showNodeDetails && nodeActionsAllowed"
        :node="node"
        :node-edit-allowed="nodeEditAllowed"
        :node-missing-oauth="nodeDetails.missingOAuthApplication"
      />
    </div>
    <geo-node-details
      v-if="showNodeDetails"
      :node="node"
      :node-details="nodeDetails"
    />
    <div
      v-if="isNodeDetailsFailed"
      class="prepend-top-10"
    >
      <p class="health-message">
        {{ errorMessage }}
      </p>
    </div>
  </li>
</template>
