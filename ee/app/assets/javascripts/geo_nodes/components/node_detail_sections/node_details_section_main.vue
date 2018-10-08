<script>
  import { __ } from '~/locale';

  import GeoNodeHealthStatus from '../geo_node_health_status.vue';
  import GeoNodeActions from '../geo_node_actions.vue';

  export default {
    components: {
      GeoNodeHealthStatus,
      GeoNodeActions,
    },
    props: {
      node: {
        type: Object,
        required: true,
      },
      nodeDetails: {
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
      versionMismatch: {
        type: Boolean,
        required: true,
      },
    },
    computed: {
      nodeVersion() {
        if (this.nodeDetails.version == null &&
            this.nodeDetails.revision == null) {
          return __('Unknown');
        }
        return `${this.nodeDetails.version} (${this.nodeDetails.revision})`;
      },
      nodeHealthStatus() {
        return this.nodeDetails.healthy ? this.nodeDetails.health : this.nodeDetails.healthStatus;
      },
    },
  };
</script>

<template>
  <div class="row-fluid clearfix node-detail-section primary-section">
    <div class="col-md-8 section-items-container">
      <div class="detail-section-item node-version">
        <div class="node-detail-title">
          {{ s__('GeoNodes|GitLab version') }}
        </div>
        <div
          :class="{ 'node-detail-value-error': versionMismatch }"
          class="node-detail-value node-detail-value-bold"
        >
          {{ nodeVersion }}
        </div>
      </div>
      <geo-node-health-status
        :status="nodeHealthStatus"
      />
    </div>
    <geo-node-actions
      :node="node"
      :node-actions-allowed="nodeActionsAllowed"
      :node-edit-allowed="nodeEditAllowed"
      :node-missing-oauth="nodeDetails.missingOAuthApplication"
    />
  </div>
</template>
