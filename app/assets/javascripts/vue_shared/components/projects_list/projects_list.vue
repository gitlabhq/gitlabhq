<script>
import {
  TIMESTAMP_TYPES,
  TIMESTAMP_TYPE_CREATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import ProjectsListItem from './projects_list_item.vue';

export default {
  name: 'ProjectsList',
  components: { ProjectsListItem },
  props: {
    items: {
      type: Array,
      required: true,
    },
    showProjectIcon: {
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
    includeMicrodata: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <ul class="gl-list-none gl-p-0">
    <projects-list-item
      v-for="project in items"
      :key="project.id"
      :project="project"
      :show-project-icon="showProjectIcon"
      :list-item-class="listItemClass"
      :timestamp-type="timestampType"
      :include-microdata="includeMicrodata"
      @refetch="$emit('refetch')"
      @hover-visibility="$emit('hover-visibility', $event)"
      @hover-stat="$emit('hover-stat', $event)"
      @click-stat="$emit('click-stat', $event)"
      @click-avatar="$emit('click-avatar')"
      @click-topic="$emit('click-topic')"
    />
  </ul>
</template>
