<script>
import geoNodeItem from './geo_node_item.vue';

export default {
  components: {
    geoNodeItem,
  },
  props: {
    nodes: {
      type: Array,
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
};
</script>

<template>
  <div class="panel panel-default">
    <geo-node-item
      v-for="(node, index) in nodes"
      :key="index"
      :node="node"
      :primary-node="node.primary"
      :node-actions-allowed="nodeActionsAllowed"
      :node-edit-allowed="nodeEditAllowed"
    />
  </div>
</template>
