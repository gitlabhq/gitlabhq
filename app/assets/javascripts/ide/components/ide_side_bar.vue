<script>
import { mapState, mapGetters } from 'vuex';
import ProjectAvatarImage from '~/vue_shared/components/project_avatar/image.vue';
import Icon from '~/vue_shared/components/icon.vue';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';
import SkeletonLoadingContainer from '~/vue_shared/components/skeleton_loading_container.vue';
import Identicon from '../../vue_shared/components/identicon.vue';
import IdeTree from './ide_tree.vue';
import ResizablePanel from './resizable_panel.vue';
import ActivityBar from './activity_bar.vue';
import CommitSection from './repo_commit_section.vue';
import IdeReview from './ide_review.vue';

export default {
  components: {
    Icon,
    PanelResizer,
    SkeletonLoadingContainer,
    ResizablePanel,
    ActivityBar,
    ProjectAvatarImage,
    Identicon,
    CommitSection,
    IdeTree,
    IdeReview,
  },
  computed: {
    ...mapState(['loading', 'currentBranchId', 'currentActivityView']),
    ...mapGetters(['currentProject']),
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
        <div class="context-header ide-context-header">
          <a
            :href="currentProject.web_url"
          >
            <div
              v-if="currentProject.avatar_url"
              class="avatar-container s40 project-avatar"
            >
              <project-avatar-image
                class="avatar-container project-avatar"
                :link-href="currentProject.path"
                :img-src="currentProject.avatar_url"
                :img-alt="currentProject.name"
                :img-size="40"
              />
            </div>
            <identicon
              v-else
              size-class="s40"
              :entity-id="currentProject.id"
              :entity-name="currentProject.name"
            />
            <div class="ide-sidebar-project-title">
              <div class="sidebar-context-title">
                {{ currentProject.name }}
              </div>
              <div
                class="sidebar-context-title ide-sidebar-branch-title"
              >
                <icon
                  name="branch"
                  css-classes="append-right-5"
                />{{ currentBranchId }}
              </div>
            </div>
          </a>
        </div>
        <div class="multi-file-commit-panel-inner-scroll">
          <component
            :is="currentActivityView"
          />
        </div>
      </template>
    </div>
  </resizable-panel>
</template>
