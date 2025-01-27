<script>
import {
  TIMESTAMP_TYPES,
  TIMESTAMP_TYPE_CREATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import GroupsListItem from './groups_list_item.vue';

export default {
  components: { GroupsListItem },
  props: {
    groups: {
      type: Array,
      required: true,
    },
    showGroupIcon: {
      type: Boolean,
      required: false,
      default: false,
    },
    listItemClass: {
      type: [String, Array, Object],
      required: false,
      default: '',
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
  <ul class="gl-list-none gl-p-0">
    <groups-list-item
      v-for="group in groups"
      :key="group.id"
      :group="group"
      :show-group-icon="showGroupIcon"
      :class="listItemClass"
      :timestamp-type="timestampType"
      @delete="$emit('delete', $event)"
    />
  </ul>
</template>
