<script>
import { mapGetters, mapActions } from 'vuex';
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
      'unresolvedDiscussionsCount',
      'discussions',
    ]),
    isLoggedIn() {
      return this.getUserData.id;
    },
    allResolved() {
      return this.unresolvedDiscussionsCount === 0;
    },
    resolveAllDiscussionsIssuePath() {
      return this.getNoteableData.create_issue_to_resolve_discussions_path;
    },
    toggeableDiscussions() {
      return this.discussions.filter(discussion => !discussion.individual_note);
    },
    allExpanded() {
      return this.toggeableDiscussions.every(discussion => discussion.expanded);
    },
  },
  methods: {
    ...mapActions(['setExpandDiscussions']),
    handleExpandDiscussions() {
      this.setExpandDiscussions({
        discussionIds: this.toggeableDiscussions.map(discussion => discussion.id),
        expanded: !this.allExpanded,
      });
    },
  },
};
</script>

<template>
  <div
    v-if="resolvableDiscussionsCount > 0"
    ref="discussionCounter"
    class="line-resolve-all-container full-width-mobile"
  >
    <div class="full-width-mobile d-flex d-sm-flex">
      <div class="line-resolve-all">
        <span
          :class="{ 'line-resolve-btn is-active': allResolved, 'line-resolve-text': !allResolved }"
        >
          <template v-if="allResolved">
            <icon name="check-circle-filled" />
            {{ __('All threads resolved') }}
          </template>
          <template v-else>
            {{ n__('%d unresolved thread', '%d unresolved threads', unresolvedDiscussionsCount) }}
          </template>
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
          :title="__('Jump to next unresolved thread')"
          class="btn btn-default discussion-next-btn"
          data-track-event="click_button"
          data-track-label="mr_next_unresolved_thread"
          data-track-property="click_next_unresolved_thread_top"
          @click="jumpToNextDiscussion"
        >
          <icon name="comment-next" />
        </button>
      </div>
      <div class="btn-group btn-group-sm" role="group">
        <button
          v-gl-tooltip
          :title="__('Toggle all threads')"
          class="btn btn-default toggle-all-discussions-btn"
          @click="handleExpandDiscussions"
        >
          <icon :name="allExpanded ? 'angle-up' : 'angle-down'" />
        </button>
      </div>
    </div>
  </div>
</template>
