<script>
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import ProjectsListItem from './projects_list_item.vue';

export default {
  components: { ProjectsListItem },
  props: {
    /**
     * Expected format:
     *
     * {
     *   id: number | string;
     *   name: string;
     *   webUrl: string;
     *   topics: string[];
     *   forksCount?: number;
     *   avatarUrl: string | null;
     *   starCount: number;
     *   visibility: string;
     *   issuesAccessLevel: string;
     *   forkingAccessLevel: string;
     *   openIssuesCount: number;
     *   permissions: {
     *     projectAccess: { accessLevel: 50 };
     *   };
     *   descriptionHtml: string;
     *   updatedAt: string;
     *   createdAt: string;
     * }[]
     */
    projects: {
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
        return [TIMESTAMP_TYPE_CREATED_AT, TIMESTAMP_TYPE_UPDATED_AT].includes(value);
      },
    },
  },
};
</script>

<template>
  <ul class="gl-p-0 gl-list-none">
    <projects-list-item
      v-for="project in projects"
      :key="project.id"
      :project="project"
      :show-project-icon="showProjectIcon"
      :class="listItemClass"
      :timestamp-type="timestampType"
      @delete="$emit('delete', $event)"
    />
  </ul>
</template>
