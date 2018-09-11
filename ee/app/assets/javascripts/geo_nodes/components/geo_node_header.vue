<script>
  import { s__ } from '~/locale';
  import icon from '~/vue_shared/components/icon.vue';
  import tooltip from '~/vue_shared/directives/tooltip';

  export default {
    components: {
      icon,
    },
    directives: {
      tooltip,
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
      nodeDetailsLoading: {
        type: Boolean,
        required: true,
      },
      nodeDetailsFailed: {
        type: Boolean,
        required: true,
      },
    },
    computed: {
      isNodeHTTP() {
        return this.node.url.startsWith('http://');
      },
      showNodeStatusIcon() {
        if (this.nodeDetailsLoading) {
          return false;
        }

        return this.isNodeHTTP || this.nodeDetailsFailed;
      },
      nodeStatusIconClass() {
        const iconClasses = 'prepend-left-10 node-status-icon';
        if (this.nodeDetailsFailed) {
          return `${iconClasses} status-icon-failure`;
        }
        return `${iconClasses} status-icon-warning`;
      },
      nodeStatusIconName() {
        if (this.nodeDetailsFailed) {
          return 'status_failed_borderless';
        }
        return 'warning';
      },
      nodeStatusIconTooltip() {
        if (this.nodeDetailsFailed) {
          return '';
        }
        return s__('GeoNodes|You have configured Geo nodes using an insecure HTTP connection. We recommend the use of HTTPS.');
      },
    },
  };
</script>

<template>
  <div class="card-header">
    <div class="row">
      <div class="col-md-8 clearfix">
        <span class="d-flex float-left append-right-10">
          <strong class="node-url">
            {{ node.url }}
          </strong>
          <gl-loading-icon
            v-if="nodeDetailsLoading || node.nodeActionActive"
            class="node-details-loading prepend-left-10 inline"
          />
          <icon
            v-tooltip
            v-if="showNodeStatusIcon"
            :name="nodeStatusIconName"
            :size="18"
            :css-classes="nodeStatusIconClass"
            :title="nodeStatusIconTooltip"
            data-container="body"
            data-placement="bottom"
          />
        </span>
        <span class="inline node-type-badges">
          <span
            v-if="node.current"
            class="node-badge current-node"
          >
            {{ s__('Current node') }}
          </span>
          <span
            v-if="node.primary"
            class="prepend-left-5 node-badge primary-node"
          >
            {{ s__('Primary') }}
          </span>
        </span>
      </div>
    </div>
  </div>
</template>
