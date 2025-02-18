<script>
import {
  TIMESTAMP_TYPES,
  TIMESTAMP_TYPE_CREATED_AT,
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
        return TIMESTAMP_TYPES.includes(value);
      },
    },
  },
};
</script>

<template>
  <ul class="gl-list-none gl-p-0">
    <projects-list-item
      v-for="project in projects"
      :key="project.id"
      :project="project"
      :show-project-icon="showProjectIcon"
      :class="listItemClass"
      :timestamp-type="timestampType"
      @refetch="$emit('refetch')"
    />
  </ul>
</template>
