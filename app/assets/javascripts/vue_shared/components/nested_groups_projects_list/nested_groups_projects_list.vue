<script>
import {
  TIMESTAMP_TYPES,
  TIMESTAMP_TYPE_CREATED_AT,
} from '~/vue_shared/components/resource_lists/constants';

export default {
  name: 'NestedGroupsProjectsList',
  props: {
    items: {
      type: Array,
      required: true,
    },
    timestampType: {
      type: String,
      required: false,
      default: TIMESTAMP_TYPE_CREATED_AT,
      validator(value) {
        return TIMESTAMP_TYPES.includes(value);
      },
    },
  },
  beforeCreate() {
    // https://v2.vuejs.org/v2/guide/components-edge-cases.html?redirect=true#Circular-References-Between-Components
    this.$options.components.NestedGroupsProjectsListItem =
      // eslint-disable-next-line global-require
      require('./nested_groups_projects_list_item.vue').default;
  },
};
</script>

<template>
  <ul class="gl-m-0 gl-w-full gl-list-none gl-p-0">
    <!-- eslint-disable-next-line vue/no-undef-components -->
    <nested-groups-projects-list-item
      v-for="item in items"
      :key="`${item.type}-${item.id}`"
      :item="item"
      :timestamp-type="timestampType"
      @load-children="$emit('load-children', $event)"
    />
  </ul>
</template>
