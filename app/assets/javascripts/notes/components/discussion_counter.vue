<script>
import { mapActions, mapGetters } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import { pluralize } from '../../lib/utils/text_utility';
import discussionNavigation from '../mixins/discussion_navigation';
import tooltip from '../../vue_shared/directives/tooltip';

export default {
  directives: {
    tooltip,
  },
  components: {
    Icon,
  },
  mixins: [discussionNavigation],
  computed: {
    ...mapGetters([
      'getUserData',
      'getNoteableData',
      'discussionCount',
      'firstUnresolvedDiscussionId',
      'resolvedDiscussionCount',
    ]),
    isLoggedIn() {
      return this.getUserData.id;
    },
    hasNextButton() {
      return this.isLoggedIn && !this.allResolved;
    },
    countText() {
      return pluralize('discussion', this.discussionCount);
    },
    allResolved() {
      return this.resolvedDiscussionCount === this.discussionCount;
    },
    resolveAllDiscussionsIssuePath() {
      return this.getNoteableData.create_issue_to_resolve_discussions_path;
    },
  },
  methods: {
    ...mapActions(['expandDiscussion']),
    jumpToFirstUnresolvedDiscussion() {
      const diffTab = window.mrTabs.currentAction === 'diffs';
      const discussionId = this.firstUnresolvedDiscussionId(diffTab);

      this.jumpToDiscussion(discussionId);
    },
  },
};
</script>

<template>
  <div v-if="discussionCount > 0" class="line-resolve-all-container prepend-top-8">
    <div>
      <div :class="{ 'has-next-btn': hasNextButton }" class="line-resolve-all">
        <span
          :class="{ 'is-active': allResolved }"
          class="line-resolve-btn is-disabled"
          type="button"
        >
          <icon name="check-circle" />
        </span>
        <span class="line-resolve-text">
          {{ resolvedDiscussionCount }}/{{ discussionCount }} {{ countText }} resolved
        </span>
      </div>
      <div v-if="resolveAllDiscussionsIssuePath && !allResolved" class="btn-group" role="group">
        <a
          v-tooltip
          :href="resolveAllDiscussionsIssuePath"
          :title="s__('Resolve all discussions in new issue')"
          data-container="body"
          class="new-issue-for-discussion btn btn-default discussion-create-issue-btn"
        >
          <icon name="issue-new" />
        </a>
      </div>
      <div v-if="isLoggedIn && !allResolved" class="btn-group" role="group">
        <button
          v-tooltip
          title="Jump to first unresolved discussion"
          data-container="body"
          class="btn btn-default discussion-next-btn"
          @click="jumpToFirstUnresolvedDiscussion"
        >
          <icon name="comment-next" />
        </button>
      </div>
    </div>
  </div>
</template>
