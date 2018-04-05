<script>
  import { s__ } from '~/locale';
  import icon from '~/vue_shared/components/icon.vue';
  import loadingIcon from '~/vue_shared/components/loading_icon.vue';
  import tooltip from '~/vue_shared/directives/tooltip';

  export default {
    components: {
      icon,
      loadingIcon,
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
        const iconClasses = 'prepend-left-10 pull-left node-status-icon';
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
  <div class="panel-heading">
    <div class="row">
      <div class="col-md-8 clearfix">
        <strong class="node-url inline pull-left">
          {{ node.url }}
        </strong>
        <loading-icon
          v-if="nodeDetailsLoading || node.nodeActionActive"
          class="node-details-loading prepend-left-10 pull-left inline"
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
            class="prepend-left-5 node-badge current-node"
            v-if="node.current"
          >
            {{ s__('Current node') }}
          </span>
          <span
            class="prepend-left-5 node-badge primary-node"
            v-if="node.primary"
          >
            {{ s__('Primary') }}
          </span>
        </span>
      </div>
    </div>
  </div>
</template>
