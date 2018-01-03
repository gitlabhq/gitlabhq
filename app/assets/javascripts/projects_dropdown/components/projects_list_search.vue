<script>
import { s__ } from '../../locale';
import projectsListItem from './projects_list_item.vue';

export default {
  components: {
    projectsListItem,
  },
  props: {
    matcher: {
      type: String,
      required: true,
    },
    projects: {
      type: Array,
      required: true,
    },
    searchFailed: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    isListEmpty() {
      return this.projects.length === 0;
    },
    listEmptyMessage() {
      return this.searchFailed ?
        s__('ProjectsDropdown|Something went wrong on our end.') :
        s__('ProjectsDropdown|Sorry, no projects matched your search');
    },
  },
};
</script>

<template>
  <div
    class="projects-list-search-container"
  >
    <ul
      class="list-unstyled"
    >
      <li
        v-if="isListEmpty"
        :class="{ 'section-failure': searchFailed }"
        class="section-empty"
      >
        {{ listEmptyMessage }}
      </li>
      <projects-list-item
        v-else
        v-for="(project, index) in projects"
        :key="index"
        :project-id="project.id"
        :project-name="project.name"
        :namespace="project.namespace"
        :web-url="project.webUrl"
        :avatar-url="project.avatarUrl"
        :matcher="matcher"
      />
    </ul>
  </div>
</template>
