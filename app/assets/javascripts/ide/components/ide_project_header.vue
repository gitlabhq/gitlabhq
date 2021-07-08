<script>
import ProjectAvatarDefault from '~/vue_shared/components/deprecated_project_avatar/default.vue';

export default {
  components: {
    ProjectAvatarDefault,
  },
  props: {
    project: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div class="context-header ide-context-header">
    <a :href="project.web_url" :title="s__('IDE|Go to project')">
      <project-avatar-default :project="project" :size="48" />
      <span class="ide-sidebar-project-title">
        <span class="sidebar-context-title"> {{ project.name }} </span>
        <span
          class="sidebar-context-title text-secondary"
          data-qa-selector="project_path_content"
          :data-qa-project-path="project.path_with_namespace"
        >
          {{ project.path_with_namespace }}
        </span>
      </span>
    </a>
  </div>
</template>
