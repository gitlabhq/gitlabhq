<script>
import loadingIcon from '~/vue_shared/components/loading_icon.vue';
import SmartInterval from '~/smart_interval';

import eventHub from '../event_hub';

import geoNodesList from './geo_nodes_list.vue';

export default {
  components: {
    loadingIcon,
    geoNodesList,
  },
  props: {
    store: {
      type: Object,
      required: true,
    },
    service: {
      type: Object,
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
      isLoading: true,
      hasError: false,
      errorMessage: '',
    };
  },
  computed: {
    nodes() {
      return this.store.getNodes();
    },
  },
  methods: {
    fetchGeoNodes() {
      this.hasError = false;
      this.service.getGeoNodes()
        .then(res => res.data)
        .then((nodes) => {
          this.store.setNodes(nodes);
          this.isLoading = false;
        })
        .catch((err) => {
          this.hasError = true;
          this.errorMessage = err;
        });
    },
    fetchNodeDetails(nodeId) {
      return this.service.getGeoNodeDetails(nodeId)
        .then(res => res.data)
        .then((nodeDetails) => {
          const primaryNodeVersion = this.store.getPrimaryNodeVersion();
          const updatedNodeDetails = Object.assign(nodeDetails, {
            primaryVersion: primaryNodeVersion.version,
            primaryRevision: primaryNodeVersion.revision,
          });
          this.store.setNodeDetails(nodeId, updatedNodeDetails);
          eventHub.$emit('nodeDetailsLoaded', this.store.getNodeDetails(nodeId));
        })
        .catch((err) => {
          this.hasError = true;
          this.errorMessage = err;
        });
    },
    initNodeDetailsPolling(nodeId) {
      this.nodePollingInterval = new SmartInterval({
        callback: this.fetchNodeDetails.bind(this, nodeId),
        startingInterval: 30000,
        maxInterval: 120000,
        hiddenInterval: 240000,
        incrementByFactorOf: 15000,
        immediateExecution: true,
      });
    },
  },
  created() {
    eventHub.$on('pollNodeDetails', this.initNodeDetailsPolling);
  },
  mounted() {
    this.fetchGeoNodes();
  },
  beforeDestroy() {
    eventHub.$off('pollNodeDetails', this.initNodeDetailsPolling);
    if (this.nodePollingInterval) {
      this.nodePollingInterval.stopTimer();
    }
  },
};
</script>

<template>
  <div class="panel panel-default">
    <div class="panel-heading">
      Geo nodes ({{nodes.length}})
    </div>
    <loading-icon
      class="loading-animation prepend-top-20 append-bottom-20"
      size="2"
      v-if="isLoading"
      :label="s__('GeoNodes|Loading nodes')"
    />
    <geo-nodes-list
      v-if="!isLoading"
      :nodes="nodes"
      :node-actions-allowed="nodeActionsAllowed"
      :node-edit-allowed="nodeEditAllowed"
    />
    <p
      class="health-message prepend-left-15 append-right-15"
      v-if="hasError"
    >
      {{errorMessage}}
    </p>
  </div>
</template>
