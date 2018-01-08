<script>
import icon from '~/vue_shared/components/icon.vue';
import loadingIcon from '~/vue_shared/components/loading_icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';

import eventHub from '../event_hub';

import geoNodeActions from './geo_node_actions.vue';
import geoNodeDetails from './geo_node_details.vue';

export default {
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
  components: {
    icon,
    loadingIcon,
    geoNodeActions,
    geoNodeDetails,
  },
  directives: {
    tooltip,
  },
  data() {
    return {
      isNodeDetailsLoading: true,
      nodeHealthStatus: '',
      nodeDetails: {},
    };
  },
  computed: {
    showInsecureUrlWarning() {
      return this.node.url.startsWith('http://');
    },
  },
  methods: {
    handleNodeDetails(nodeDetails) {
      if (this.node.id === nodeDetails.id) {
        this.isNodeDetailsLoading = false;
        this.nodeDetails = nodeDetails;
        this.nodeHealthStatus = nodeDetails.health;
      }
    },
    handleMounted() {
      eventHub.$emit('pollNodeDetails', this.node.id);
    },
  },
  created() {
    eventHub.$on('nodeDetailsLoaded', this.handleNodeDetails);
  },
  mounted() {
    this.handleMounted();
  },
  beforeDestroy() {
    eventHub.$off('nodeDetailsLoaded', this.handleNodeDetails);
  },
};
</script>

<template>
  <li>
    <div class="row">
      <div class="col-md-8">
        <div class="row">
          <div class="col-md-8 clearfix">
            <strong class="node-url inline pull-left">
              {{node.url}}
            </strong>
            <loading-icon
              v-if="isNodeDetailsLoading"
              class="node-details-loading prepend-left-10 pull-left inline"
              size=1
            />
            <icon
              v-tooltip
              v-if="!isNodeDetailsLoading && showInsecureUrlWarning"
              css-classes="prepend-left-10 pull-left node-url-warning"
              name="warning"
              data-container="body"
              data-placement="bottom"
              :title="s__('GeoNodes|You have configured Geo nodes using an insecure HTTP connection. We recommend the use of HTTPS.')"
              :size="18"
            />
            <span class="inline pull-left prepend-left-10">
              <span
                class="node-badge current-node"
                v-if="node.current"
              >
                {{s__('Current node')}}
              </span>
              <span
                class="node-badge primary-node"
                v-if="node.primary"
              >
                {{s__('Primary')}}
              </span>
            </span>
          </div>
        </div>
      </div>
      <geo-node-actions
        v-if="!isNodeDetailsLoading && nodeActionsAllowed"
        :node="node"
        :node-edit-allowed="nodeEditAllowed"
        :node-missing-oauth="nodeDetails.missingOAuthApplication"
      />
    </div>
    <geo-node-details
      v-if="!isNodeDetailsLoading"
      :node="node"
      :node-details="nodeDetails"
    />
  </li>
</template>
