<script>
import BranchesTree from './ide_project_branches_tree.vue';
import projectAvatarImage from '../../vue_shared/components/project_avatar/project_avatar_image.vue';

export default {
  components: {
    BranchesTree,
    projectAvatarImage,
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
  <div class="projects-sidebar">
    <div class="context-header">
      <a 
        :title="project.name" 
        :href="project.path">
        <div class="avatar-container s40 project-avatar">
          <project-avatar-image
            class="avatar-container project-avatar"
            :link-href="project.path"
            :img-src="project.avatar_url"
            :img-alt="project.name"
            :img-size="40"
            />
        </div>
        <div class="sidebar-context-title">
          {{ project.name }}
        </div>
      </a>
    </div>
    <div>
      <branches-tree
        v-for="(branch, index) in project.branches"
        :key="branch.name"
        :branch="branch"/>
    </div>
  </div>
</template>
