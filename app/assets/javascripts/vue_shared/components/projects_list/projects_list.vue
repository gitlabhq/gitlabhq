<script>
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
     *   }[];
     */
    projects: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <ul class="gl-p-0 gl-list-style-none">
    <projects-list-item v-for="project in projects" :key="project.id" :project="project" />
  </ul>
</template>
