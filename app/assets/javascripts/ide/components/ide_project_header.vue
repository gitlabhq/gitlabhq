<script>
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';

export default {
  components: {
    ProjectAvatar,
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
    <a :href="project.web_url" :title="s__('IDE|Go to project')" data-testid="go-to-project-link">
      <project-avatar
        :project-name="project.name"
        :project-avatar-url="project.avatar_url"
        :size="48"
      />
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
