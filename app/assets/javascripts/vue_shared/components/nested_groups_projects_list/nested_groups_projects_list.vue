<script>
import {
  TIMESTAMP_TYPES,
  TIMESTAMP_TYPE_CREATED_AT,
} from '~/vue_shared/components/resource_lists/constants';

/**
 * This component uses circular references.
 * https://v2.vuejs.org/v2/guide/components-edge-cases.html#Circular-References-Between-Components
 * To use this component you must globally register `NestedGroupsProjectsList` and `NestedGroupsProjectsListItem`.
 *
 * Example:
 *
 * Vue.component('NestedGroupsProjectsList', NestedGroupsProjectsList);
 * Vue.component('NestedGroupsProjectsListItem', NestedGroupsProjectsListItem);
 */

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
