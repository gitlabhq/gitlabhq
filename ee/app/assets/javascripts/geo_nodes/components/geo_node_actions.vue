<script>
  import { __, s__ } from '~/locale';
  import eventHub from '../event_hub';
  import { NODE_ACTIONS } from '../constants';

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
    computed: {
      isToggleAllowed() {
        return !this.node.primary && this.nodeEditAllowed;
      },
      nodeToggleLabel() {
        return this.node.enabled ? __('Disable') : __('Enable');
      },
    },
    methods: {
      onToggleNode() {
        eventHub.$emit('showNodeActionModal', {
          actionType: NODE_ACTIONS.TOGGLE,
          node: this.node,
          modalMessage: s__('GeoNodes|Disabling a node stops the sync process. Are you sure?'),
          modalActionLabel: this.nodeToggleLabel,
        });
      },
      onRemoveNode() {
        eventHub.$emit('showNodeActionModal', {
          actionType: NODE_ACTIONS.REMOVE,
          node: this.node,
          modalKind: 'danger',
          modalMessage: s__('GeoNodes|Removing a node stops the sync process. Are you sure?'),
          modalActionLabel: __('Remove'),
        });
      },
      onRepairNode() {
        eventHub.$emit('repairNode', this.node);
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
      <button
        type="button"
        class="btn btn-default btn-sm btn-node-action"
        @click="onRepairNode"
      >
        {{ s__('Repair authentication') }}
      </button>
    </div>
    <div
      v-if="isToggleAllowed"
      class="node-action-container"
    >
      <button
        :class="{
          'btn-warning': node.enabled,
          'btn-success': !node.enabled
        }"
        type="button"
        class="btn btn-sm btn-node-action"
        @click="onToggleNode"
      >
        {{ nodeToggleLabel }}
      </button>
    </div>
    <div
      v-if="nodeEditAllowed"
      class="node-action-container"
    >
      <a
        :href="node.editPath"
        class="btn btn-sm btn-node-action"
      >
        {{ __('Edit') }}
      </a>
    </div>
    <div class="node-action-container">
      <button
        type="button"
        class="btn btn-sm btn-node-action btn-danger"
        @click="onRemoveNode"
      >
        {{ __('Remove') }}
      </button>
    </div>
  </div>
</template>
