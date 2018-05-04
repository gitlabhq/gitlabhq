<script>
import eventHub from '../event_hub';

import GeoNodeHeader from './geo_node_header.vue';
import GeoNodeDetails from './geo_node_details.vue';

export default {
  components: {
    GeoNodeHeader,
    GeoNodeDetails,
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
    showNodeDetails() {
      if (!this.isNodeDetailsLoading) {
        return !this.isNodeDetailsFailed;
      }
      return false;
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
  <div
    class="panel panel-default geo-node-item"
    :class="{ 'node-action-active': node.nodeActionActive }"
  >
    <geo-node-header
      :node="node"
      :node-details="nodeDetails"
      :node-details-loading="isNodeDetailsLoading"
      :node-details-failed="isNodeDetailsFailed"
    />
    <geo-node-details
      v-if="showNodeDetails"
      :node="node"
      :node-details="nodeDetails"
      :node-edit-allowed="nodeEditAllowed"
      :node-actions-allowed="nodeActionsAllowed"
    />
    <div
      v-if="isNodeDetailsFailed"
      class="node-health-message-container"
    >
      <p class="health-message node-health-message">
        {{ errorMessage }}
      </p>
    </div>
  </div>
</template>
