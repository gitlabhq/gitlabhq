<script>
  import { s__ } from '../../locale';
  import projectsListItem from './projects_list_item.vue';

  export default {
    components: {
      projectsListItem,
    },
    props: {
      projects: {
        type: Array,
        required: true,
      },
      localStorageFailed: {
        type: Boolean,
        required: true,
      },
    },
    computed: {
      isListEmpty() {
        return this.projects.length === 0;
      },
      listEmptyMessage() {
        return this.localStorageFailed ?
          s__('ProjectsDropdown|This feature requires browser localStorage support') :
          s__('ProjectsDropdown|Projects you visit often will appear here');
      },
    },
  };
</script>

<template>
  <div
    class="projects-list-frequent-container"
  >
    <ul
      class="list-unstyled"
    >
      <li
        class="section-empty"
        v-if="isListEmpty"
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
      />
    </ul>
  </div>
</template>
