<script>
import { mapState, mapGetters } from 'vuex';
import SkeletonLoadingContainer from '~/vue_shared/components/skeleton_loading_container.vue';
import IdeTree from './ide_tree.vue';
import ResizablePanel from './resizable_panel.vue';
import ActivityBar from './activity_bar.vue';
import CommitSection from './repo_commit_section.vue';
import CommitForm from './commit_sidebar/form.vue';
import IdeReview from './ide_review.vue';
import SuccessMessage from './commit_sidebar/success_message.vue';
import IdeProjectHeader from './ide_project_header.vue';
import { activityBarViews } from '../constants';

export default {
  components: {
    SkeletonLoadingContainer,
    ResizablePanel,
    ActivityBar,
    CommitSection,
    IdeTree,
    CommitForm,
    IdeReview,
    SuccessMessage,
    IdeProjectHeader,
  },
  computed: {
    ...mapState([
      'loading',
      'currentActivityView',
      'changedFiles',
      'stagedFiles',
      'lastCommitMsg',
    ]),
    ...mapGetters(['currentProject', 'someUncommitedChanges']),
    showSuccessMessage() {
      return (
        this.currentActivityView === activityBarViews.edit &&
        (this.lastCommitMsg && !this.someUncommitedChanges)
      );
    },
  },
};
</script>

<template>
  <resizable-panel
    :collapsible="false"
    :initial-width="340"
    side="left"
    class="flex-column"
  >
    <template v-if="loading">
      <div class="multi-file-commit-panel-inner">
        <div
          v-for="n in 3"
          :key="n"
          class="multi-file-loading-container"
        >
          <skeleton-loading-container />
        </div>
      </div>
    </template>
    <template v-else>
      <ide-project-header
        :project="currentProject"
      />
      <div class="ide-context-body d-flex flex-fill">
        <activity-bar />
        <div class="multi-file-commit-panel-inner">
          <div class="multi-file-commit-panel-inner-content">
            <component
              :is="currentActivityView"
            />
          </div>
          <commit-form />
        </div>
      </div>
    </template>
  </resizable-panel>
</template>
