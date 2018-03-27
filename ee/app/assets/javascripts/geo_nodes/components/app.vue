<script>
import { s__ } from '~/locale';
import Flash from '~/flash';
import statusCodes from '~/lib/utils/http_status';
import loadingIcon from '~/vue_shared/components/loading_icon.vue';
import DeprecatedModal from '~/vue_shared/components/deprecated_modal.vue';
import SmartInterval from '~/smart_interval';

import eventHub from '../event_hub';

import { NODE_ACTIONS } from '../constants';

import geoNodesList from './geo_nodes_list.vue';

export default {
  components: {
    loadingIcon,
    DeprecatedModal,
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
      showModal: false,
      targetNode: null,
      targetNodeActionType: '',
      modalKind: 'warning',
      modalMessage: '',
      modalActionLabel: '',
      errorMessage: '',
    };
  },
  computed: {
    nodes() {
      return this.store.getNodes();
    },
  },
  created() {
    eventHub.$on('pollNodeDetails', this.initNodeDetailsPolling);
    eventHub.$on('showNodeActionModal', this.showNodeActionModal);
    eventHub.$on('repairNode', this.repairNode);
  },
  mounted() {
    this.fetchGeoNodes();
  },
  beforeDestroy() {
    eventHub.$off('pollNodeDetails', this.initNodeDetailsPolling);
    eventHub.$off('showNodeActionModal', this.showNodeActionModal);
    eventHub.$off('repairNode', this.repairNode);
    if (this.nodePollingInterval) {
      this.nodePollingInterval.stopTimer();
    }
  },
  methods: {
    setNodeActionStatus(node, status) {
      Object.assign(node, { nodeActionActive: status });
    },
    initNodeDetailsPolling(node) {
      this.nodePollingInterval = new SmartInterval({
        callback: this.fetchNodeDetails.bind(this, node),
        startingInterval: 30000,
        maxInterval: 120000,
        hiddenInterval: 240000,
        incrementByFactorOf: 15000,
        immediateExecution: true,
      });
    },
    fetchGeoNodes() {
      this.hasError = false;
      this.service
        .getGeoNodes()
        .then(res => res.data)
        .then(nodes => {
          this.store.setNodes(nodes);
          this.isLoading = false;
        })
        .catch(err => {
          this.hasError = true;
          this.errorMessage = err;
        });
    },
    fetchNodeDetails(node) {
      const nodeId = node.id;
      return this.service
        .getGeoNodeDetails(node)
        .then(res => res.data)
        .then(nodeDetails => {
          const primaryNodeVersion = this.store.getPrimaryNodeVersion();
          const updatedNodeDetails = Object.assign(nodeDetails, {
            primaryVersion: primaryNodeVersion.version,
            primaryRevision: primaryNodeVersion.revision,
          });
          this.store.setNodeDetails(nodeId, updatedNodeDetails);
          eventHub.$emit(
            'nodeDetailsLoaded',
            this.store.getNodeDetails(nodeId),
          );
        })
        .catch(err => {
          if (err.response && err.response.status === statusCodes.NOT_FOUND) {
            this.store.setNodeDetails(nodeId, {
              geo_node_id: nodeId,
              health: err.message,
              health_status: 'Unknown',
              missing_oauth_application: false,
              sync_status_unavailable: true,
              storage_shards_match: null,
            });
            eventHub.$emit(
              'nodeDetailsLoaded',
              this.store.getNodeDetails(nodeId),
            );
          } else {
            eventHub.$emit('nodeDetailsLoadFailed', nodeId, err);
          }
        });
    },
    repairNode(targetNode) {
      this.setNodeActionStatus(targetNode, true);
      this.service
        .repairNode(targetNode)
        .then(() => {
          this.setNodeActionStatus(targetNode, false);
          Flash(
            s__('GeoNodes|Node Authentication was successfully repaired.'),
            'notice',
          );
        })
        .catch(() => {
          this.setNodeActionStatus(targetNode, false);
          Flash(s__('GeoNodes|Something went wrong while repairing node'));
        });
    },
    toggleNode(targetNode) {
      this.setNodeActionStatus(targetNode, true);
      this.service
        .toggleNode(targetNode)
        .then(res => res.data)
        .then(node => {
          Object.assign(targetNode, {
            enabled: node.enabled,
            nodeActionActive: false,
          });
        })
        .catch(() => {
          this.setNodeActionStatus(targetNode, false);
          Flash(
            s__('GeoNodes|Something went wrong while changing node status'),
          );
        });
    },
    removeNode(targetNode) {
      this.setNodeActionStatus(targetNode, true);
      this.service
        .removeNode(targetNode)
        .then(() => {
          this.store.removeNode(targetNode);
          Flash(s__('GeoNodes|Node was successfully removed.'), 'notice');
        })
        .catch(() => {
          this.setNodeActionStatus(targetNode, false);
          Flash(s__('GeoNodes|Something went wrong while removing node'));
        });
    },
    handleNodeAction() {
      this.showModal = false;

      if (this.targetNodeActionType === NODE_ACTIONS.TOGGLE) {
        this.toggleNode(this.targetNode);
      } else if (this.targetNodeActionType === NODE_ACTIONS.REMOVE) {
        this.removeNode(this.targetNode);
      }
    },
    showNodeActionModal({
      actionType,
      node,
      modalKind = 'warning',
      modalMessage,
      modalActionLabel,
    }) {
      this.targetNode = node;
      this.targetNodeActionType = actionType;
      this.modalKind = modalKind;
      this.modalMessage = modalMessage;
      this.modalActionLabel = modalActionLabel;

      if (actionType === NODE_ACTIONS.TOGGLE && !node.enabled) {
        this.toggleNode(this.targetNode);
      } else {
        this.showModal = true;
      }
    },
    hideNodeActionModal() {
      this.showModal = false;
    },
  },
};
</script>

<template>
  <div class="panel panel-default">
    <div class="panel-heading">
      Geo nodes ({{ nodes.length }})
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
      {{ errorMessage }}
    </p>
    <deprecated-modal
      v-show="showModal"
      :title="__('Are you sure?')"
      :kind="modalKind"
      :text="modalMessage"
      :primary-button-label="modalActionLabel"
      @cancel="hideNodeActionModal"
      @submit="handleNodeAction"
    />
  </div>
</template>
