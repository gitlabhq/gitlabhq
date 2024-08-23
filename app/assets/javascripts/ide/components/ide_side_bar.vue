<script>
import { GlSkeletonLoader } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters } from 'vuex';
import { SIDEBAR_INIT_WIDTH, leftSidebarViews } from '../constants';
import ActivityBar from './activity_bar.vue';
import CommitForm from './commit_sidebar/form.vue';
import IdeProjectHeader from './ide_project_header.vue';
import IdeTree from './ide_tree.vue';
import ResizablePanel from './resizable_panel.vue';

export default {
  components: {
    GlSkeletonLoader,
    ResizablePanel,
    ActivityBar,
    IdeTree,
    [leftSidebarViews.review.name]: () =>
      import(/* webpackChunkName: 'ide_runtime' */ './ide_review.vue'),
    [leftSidebarViews.commit.name]: () =>
      import(/* webpackChunkName: 'ide_runtime' */ './repo_commit_section.vue'),
    CommitForm,
    IdeProjectHeader,
  },
  computed: {
    ...mapState(['loading', 'currentActivityView', 'changedFiles', 'stagedFiles', 'lastCommitMsg']),
    ...mapGetters(['currentProject', 'someUncommittedChanges']),
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
      <div class="multi-file-commit-panel-inner" data-testid="ide-side-bar-inner">
        <div v-for="n in 3" :key="n" class="multi-file-loading-container">
          <gl-skeleton-loader />
        </div>
      </div>
    </template>
    <template v-else>
      <ide-project-header :project="currentProject" />
      <div class="ide-context-body flex-fill gl-flex">
        <activity-bar />
        <div class="multi-file-commit-panel-inner" data-testid="ide-side-bar-inner">
          <div class="multi-file-commit-panel-inner-content">
            <keep-alive>
              <component :is="currentActivityView" @tree-ready="$emit('tree-ready')" />
            </keep-alive>
          </div>
          <commit-form />
        </div>
      </div>
    </template>
  </resizable-panel>
</template>
