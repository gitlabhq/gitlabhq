<script>
<<<<<<< HEAD
import projectAvatarImage from '~/vue_shared/components/project_avatar/image.vue';
import branchesTree from './ide_project_branches_tree.vue';
import externalLinks from './ide_external_links.vue';

export default {
  components: {
    branchesTree,
    externalLinks,
    projectAvatarImage,
=======
import ProjectAvatarImage from '~/vue_shared/components/project_avatar/image.vue';
import Identicon from '../../vue_shared/components/identicon.vue';
import BranchesTree from './ide_project_branches_tree.vue';
import ExternalLinks from './ide_external_links.vue';

export default {
  components: {
    BranchesTree,
    ExternalLinks,
    ProjectAvatarImage,
    Identicon,
>>>>>>> upstream/master
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
        :href="project.web_url"
      >
<<<<<<< HEAD
        <div class="avatar-container s40 project-avatar">
=======
        <div
          v-if="project.avatar_url"
          class="avatar-container s40 project-avatar"
        >
>>>>>>> upstream/master
          <project-avatar-image
            class="avatar-container project-avatar"
            :link-href="project.path"
            :img-src="project.avatar_url"
            :img-alt="project.name"
            :img-size="40"
          />
        </div>
<<<<<<< HEAD
=======
        <identicon
          v-else
          size-class="s40"
          :entity-id="project.id"
          :entity-name="project.name"
        />
>>>>>>> upstream/master
        <div class="sidebar-context-title">
          {{ project.name }}
        </div>
      </a>
    </div>
    <external-links
      :project-url="project.web_url"
    />
    <div class="multi-file-commit-panel-inner-scroll">
      <branches-tree
        v-for="branch in project.branches"
        :key="branch.name"
        :project-id="project.path_with_namespace"
        :branch="branch"
      />
    </div>
  </div>
</template>
