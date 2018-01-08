<script>
import { __, s__ } from '~/locale';
import loadingIcon from '~/vue_shared/components/loading_icon.vue';

import { NODE_ACTION_BASE_PATH, NODE_ACTIONS } from '../constants';

export default {
  props: {
    node: {
      type: Object,
      required: true,
    },
    nodeEditAllowed: {
      type: Boolean,
      required: true,
    },
    nodeMissingOauth: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      isNodeToggleInProgress: false,
    };
  },
  components: {
    loadingIcon,
  },
  computed: {
    isToggleAllowed() {
      return !this.node.primary && this.nodeEditAllowed;
    },
    nodeToggleLabel() {
      return this.node.enabled ? __('Disable') : __('Enable');
    },
    nodeDisableMessage() {
      return this.node.enabled ? s__('GeoNodes|Disabling a node stops the sync process. Are you sure?') : '';
    },
    nodePath() {
      return `${NODE_ACTION_BASE_PATH}${this.node.id}`;
    },
    nodeRepairAuthPath() {
      return `${this.nodePath}${NODE_ACTIONS.REPAIR}`;
    },
    nodeTogglePath() {
      return `${this.nodePath}${NODE_ACTIONS.TOGGLE}`;
    },
    nodeEditPath() {
      return `${this.nodePath}${NODE_ACTIONS.EDIT}`;
    },
  },
};
</script>

<template>
  <div class="geo-node-actions">
    <div
      v-if="nodeMissingOauth"
      class="node-action-container"
    >
      <a
        class="btn btn-default btn-sm btn-node-action"
        data-method="post"
        :href="nodeRepairAuthPath"
      >
        {{s__('Repair authentication')}}
      </a>
    </div>
    <div
      v-if="isToggleAllowed"
      class="node-action-container"
    >
      <a
        class="btn btn-sm btn-node-action"
        data-method="post"
        :href="nodeTogglePath"
        :data-confirm="nodeDisableMessage"
        :class="{ 'btn-warning': node.enabled, 'btn-success': !node.enabled }"
      >
        {{nodeToggleLabel}}
      </a>
    </div>
    <div
      v-if="nodeEditAllowed"
      class="node-action-container"
    >
      <a
        class="btn btn-sm btn-node-action"
        :href="nodeEditPath"
      >
        {{__('Edit')}}
      </a>
    </div>
    <div class="node-action-container">
      <a
        class="btn btn-sm btn-node-action btn-danger"
        data-method="delete"
        :href="nodePath"
      >
        {{__('Remove')}}
      </a>
    </div>
  </div>
</template>
