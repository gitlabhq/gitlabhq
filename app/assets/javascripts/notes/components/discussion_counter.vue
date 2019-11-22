<script>
import { mapActions, mapGetters } from 'vuex';
import { GlTooltipDirective } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import discussionNavigation from '../mixins/discussion_navigation';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    Icon,
  },
  mixins: [discussionNavigation],
  computed: {
    ...mapGetters([
      'getUserData',
      'getNoteableData',
      'resolvableDiscussionsCount',
      'firstUnresolvedDiscussionId',
      'unresolvedDiscussionsCount',
      'getDiscussion',
    ]),
    isLoggedIn() {
      return this.getUserData.id;
    },
    hasNextButton() {
      return this.isLoggedIn && !this.allResolved;
    },
    allResolved() {
      return this.unresolvedDiscussionsCount === 0;
    },
    resolveAllDiscussionsIssuePath() {
      return this.getNoteableData.create_issue_to_resolve_discussions_path;
    },
    resolvedDiscussionsCount() {
      return this.resolvableDiscussionsCount - this.unresolvedDiscussionsCount;
    },
  },
  methods: {
    ...mapActions(['expandDiscussion']),
    jumpToFirstUnresolvedDiscussion() {
      const diffTab = window.mrTabs.currentAction === 'diffs';
      const discussionId =
        this.firstUnresolvedDiscussionId(diffTab) || this.firstUnresolvedDiscussionId();
      const firstDiscussion = this.getDiscussion(discussionId);
      this.jumpToDiscussion(firstDiscussion);
    },
  },
};
</script>

<template>
  <div v-if="resolvableDiscussionsCount > 0" class="line-resolve-all-container full-width-mobile">
    <div class="full-width-mobile d-flex d-sm-block">
      <div :class="{ 'has-next-btn': hasNextButton }" class="line-resolve-all">
        <span
          :class="{ 'is-active': allResolved }"
          class="line-resolve-btn is-disabled"
          type="button"
        >
          <icon :name="allResolved ? 'check-circle-filled' : 'check-circle'" />
        </span>
        <span class="line-resolve-text">
          {{ resolvedDiscussionsCount }}/{{ resolvableDiscussionsCount }}
          {{ n__('thread resolved', 'threads resolved', resolvableDiscussionsCount) }}
        </span>
      </div>
      <div
        v-if="resolveAllDiscussionsIssuePath && !allResolved"
        class="btn-group btn-group-sm"
        role="group"
      >
        <a
          v-gl-tooltip
          :href="resolveAllDiscussionsIssuePath"
          :title="s__('Resolve all threads in new issue')"
          class="new-issue-for-discussion btn btn-default discussion-create-issue-btn"
        >
          <icon name="issue-new" />
        </a>
      </div>
      <div v-if="isLoggedIn && !allResolved" class="btn-group btn-group-sm" role="group">
        <button
          v-gl-tooltip
          title="Jump to first unresolved thread"
          class="btn btn-default discussion-next-btn"
          @click="jumpToFirstUnresolvedDiscussion"
        >
          <icon name="comment-next" />
        </button>
      </div>
    </div>
  </div>
</template>
