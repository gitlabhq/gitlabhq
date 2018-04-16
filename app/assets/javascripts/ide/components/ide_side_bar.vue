<script>
import { mapState, mapGetters } from 'vuex';
import ProjectAvatarImage from '~/vue_shared/components/project_avatar/image.vue';
import icon from '~/vue_shared/components/icon.vue';
import panelResizer from '~/vue_shared/components/panel_resizer.vue';
import skeletonLoadingContainer from '~/vue_shared/components/skeleton_loading_container.vue';
import Identicon from '../../vue_shared/components/identicon.vue';
import projectTree from './ide_project_tree.vue';
import ResizablePanel from './resizable_panel.vue';
import ActivityBar from './activity_bar.vue';
import CommitSection from './repo_commit_section.vue';

export default {
  components: {
    projectTree,
    icon,
    panelResizer,
    skeletonLoadingContainer,
    ResizablePanel,
    ActivityBar,
    ProjectAvatarImage,
    Identicon,
    CommitSection,
  },
  computed: {
    ...mapState(['loading']),
    ...mapGetters(['currentProjectWithTree', 'activityBarComponent']),
  },
};
</script>

<template>
  <resizable-panel
    :collapsible="false"
    :initial-width="340"
    side="left"
  >
    <activity-bar
      v-if="!loading"
    />
    <div class="multi-file-commit-panel-inner">
      <template v-if="loading">
        <div
          class="multi-file-loading-container"
          v-for="n in 3"
          :key="n"
        >
          <skeleton-loading-container />
        </div>
      </template>
      <template v-else>
        <div class="context-header">
          <a
            :title="currentProjectWithTree.name"
            :href="currentProjectWithTree.web_url"
          >
            <div
              v-if="currentProjectWithTree.avatar_url"
              class="avatar-container s40 project-avatar"
            >
              <project-avatar-image
                class="avatar-container project-avatar"
                :link-href="currentProjectWithTree.path"
                :img-src="currentProjectWithTree.avatar_url"
                :img-alt="currentProjectWithTree.name"
                :img-size="40"
              />
            </div>
            <identicon
              v-else
              size-class="s40"
              :entity-id="currentProjectWithTree.id"
              :entity-name="currentProjectWithTree.name"
            />
            <div class="sidebar-context-title">
              {{ currentProjectWithTree.name }}
            </div>
          </a>
        </div>
        <div class="multi-file-commit-panel-inner-scroll">
          <component
            :is="activityBarComponent"
          />
        </div>
      </template>
    </div>
  </resizable-panel>
</template>
