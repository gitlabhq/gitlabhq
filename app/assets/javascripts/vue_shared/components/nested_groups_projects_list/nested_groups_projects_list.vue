<script>
import {
  TIMESTAMP_TYPES,
  TIMESTAMP_TYPE_CREATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import { COMPONENT_NAME } from './constants';

export default {
  name: COMPONENT_NAME,
  components: {
    NestedGroupsProjectsListItem: () => import('./nested_groups_projects_list_item.vue'),
  },
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
    includeMicrodata: {
      type: Boolean,
      required: false,
      default: false,
    },
    /**
     * Allows the parent component to override `isExpanded`.
     * This is needed when searching as we want the tree to be open after searching.
     */
    expandedOverride: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <ul class="gl-m-0 gl-w-full gl-list-none gl-p-0" data-testid="nested-groups-projects-list">
    <!-- eslint-disable-next-line vue/no-undef-components -->
    <nested-groups-projects-list-item
      v-for="item in items"
      :key="`${item.type}-${item.id}`"
      :item="item"
      :timestamp-type="timestampType"
      :include-microdata="includeMicrodata"
      :expanded-override="expandedOverride"
      @load-children="$emit('load-children', $event)"
      @refetch="$emit('refetch')"
      @hover-visibility="$emit('hover-visibility', $event)"
      @hover-stat="$emit('hover-stat', $event)"
      @click-avatar="$emit('click-avatar')"
    />
    <slot></slot>
  </ul>
</template>
