<script>
import { mapGetters, mapActions } from 'vuex';
import { GlTooltipDirective, GlIcon, GlButton, GlButtonGroup } from '@gitlab/ui';
import { __ } from '~/locale';
import discussionNavigation from '../mixins/discussion_navigation';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
    GlButton,
    GlButtonGroup,
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
    lineResolveClass() {
      return this.allResolved ? 'line-resolve-btn is-active' : 'line-resolve-text';
    },
    toggleThreadsLabel() {
      return this.allExpanded ? __('Collapse all threads') : __('Expand all threads');
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
    class="line-resolve-all-container full-width-mobile gl-display-flex d-sm-flex"
  >
    <div class="line-resolve-all">
      <span :class="lineResolveClass">
        <template v-if="allResolved">
          <gl-icon name="check-circle-filled" />
          {{ __('All threads resolved') }}
        </template>
        <template v-else>
          {{ n__('%d unresolved thread', '%d unresolved threads', unresolvedDiscussionsCount) }}
        </template>
      </span>
    </div>
    <gl-button-group>
      <gl-button
        v-if="resolveAllDiscussionsIssuePath && !allResolved"
        v-gl-tooltip
        :href="resolveAllDiscussionsIssuePath"
        :title="s__('Resolve all threads in new issue')"
        :aria-label="s__('Resolve all threads in new issue')"
        class="new-issue-for-discussion discussion-create-issue-btn"
        icon="issue-new"
      />
      <gl-button
        v-if="isLoggedIn && !allResolved"
        v-gl-tooltip
        :title="__('Jump to next unresolved thread')"
        :aria-label="__('Jump to next unresolved thread')"
        class="discussion-next-btn"
        data-track-event="click_button"
        data-track-label="mr_next_unresolved_thread"
        data-track-property="click_next_unresolved_thread_top"
        icon="comment-next"
        @click="jumpToNextDiscussion"
      />
      <gl-button
        v-gl-tooltip
        :title="toggleThreadsLabel"
        :aria-label="toggleThreadsLabel"
        class="toggle-all-discussions-btn"
        :icon="allExpanded ? 'angle-up' : 'angle-down'"
        @click="handleExpandDiscussions"
      />
    </gl-button-group>
  </div>
</template>
