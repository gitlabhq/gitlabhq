<script>
import { mapState, mapGetters } from 'vuex';
import { GlSkeletonLoading } from '@gitlab/ui';
import IdeTree from './ide_tree.vue';
import ResizablePanel from './resizable_panel.vue';
import ActivityBar from './activity_bar.vue';
import RepoCommitSection from './repo_commit_section.vue';
import CommitForm from './commit_sidebar/form.vue';
import IdeReview from './ide_review.vue';
import SuccessMessage from './commit_sidebar/success_message.vue';
import IdeProjectHeader from './ide_project_header.vue';
import { leftSidebarViews, SIDEBAR_INIT_WIDTH } from '../constants';

export default {
  components: {
    GlSkeletonLoading,
    ResizablePanel,
    ActivityBar,
    RepoCommitSection,
    IdeTree,
    CommitForm,
    IdeReview,
    SuccessMessage,
    IdeProjectHeader,
  },
  computed: {
    ...mapState(['loading', 'currentActivityView', 'changedFiles', 'stagedFiles', 'lastCommitMsg']),
    ...mapGetters(['currentProject', 'someUncommittedChanges']),
    showSuccessMessage() {
      return (
        this.currentActivityView === leftSidebarViews.edit.name &&
        (this.lastCommitMsg && !this.someUncommittedChanges)
      );
    },
  },
  SIDEBAR_INIT_WIDTH,
};
</script>

<template>
  <resizable-panel
    :initial-width="$options.SIDEBAR_INIT_WIDTH"
    side="left"
    class="multi-file-commit-panel flex-column"
  >
    <template v-if="loading">
      <div class="multi-file-commit-panel-inner">
        <div v-for="n in 3" :key="n" class="multi-file-loading-container">
          <gl-skeleton-loading />
        </div>
      </div>
    </template>
    <template v-else>
      <ide-project-header :project="currentProject" />
      <div class="ide-context-body d-flex flex-fill">
        <activity-bar />
        <div class="multi-file-commit-panel-inner">
          <div class="multi-file-commit-panel-inner-content">
            <component :is="currentActivityView" />
          </div>
          <commit-form />
        </div>
      </div>
    </template>
  </resizable-panel>
</template>
