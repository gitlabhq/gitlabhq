<script>
import { mapGetters } from 'vuex';
import resolveSvg from 'icons/_icon_resolve_discussion.svg';
import resolvedSvg from 'icons/_icon_status_success_solid.svg';
import mrIssueSvg from 'icons/_icon_mr_issue.svg';
import nextDiscussionSvg from 'icons/_next_discussion.svg';
import { pluralize } from '../../lib/utils/text_utility';
import { scrollToElement } from '../../lib/utils/common_utils';
import tooltip from '../../vue_shared/directives/tooltip';

export default {
  directives: {
    tooltip,
  },
  computed: {
    ...mapGetters([
      'getUserData',
      'getNoteableData',
      'discussionCount',
      'unresolvedDiscussions',
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
    firstUnresolvedDiscussionId() {
      return (this.unresolvedDiscussions[0] || {}).id;
    },
  },
  created() {
    this.resolveSvg = resolveSvg;
    this.resolvedSvg = resolvedSvg;
    this.mrIssueSvg = mrIssueSvg;
    this.nextDiscussionSvg = nextDiscussionSvg;
  },
  methods: {
    jumpToFirstDiscussion() {
      const el = document.querySelector(
        `[data-discussion-id="${this.firstUnresolvedDiscussionId}"]`,
      );
      const activeTab = window.mrTabs.currentAction;

      if (activeTab === 'commits' || activeTab === 'pipelines') {
        window.mrTabs.activateTab('show');
      }

      if (el) {
        scrollToElement(el);
      }
    },
  },
};
</script>

<template>
  <div class="line-resolve-all-container prepend-top-10">
    <div
      v-if="discussionCount > 0"
      :class="{ 'has-next-btn': hasNextButton }"
      class="line-resolve-all">
      <span
        :class="{ 'is-active': allResolved }"
        class="line-resolve-btn is-disabled"
        type="button">
        <span
          v-if="allResolved"
          v-html="resolvedSvg"
        ></span>
        <span
          v-else
          v-html="resolveSvg"
        ></span>
      </span>
      <span>
        {{resolvedDiscussionCount}}/{{discussionCount}} {{countText}} resolved
      </span>
    </div>
    <div
      v-if="resolveAllDiscussionsIssuePath && !allResolved"
      class="btn-group"
      role="group">
      <a
        :href="resolveAllDiscussionsIssuePath"
        v-tooltip
        title="Resolve all discussions in new issue"
        data-container="body"
        class="new-issue-for-discussion btn btn-default discussion-create-issue-btn">
        <span v-html="mrIssueSvg"></span>
      </a>
    </div>
    <div
      v-if="isLoggedIn && !allResolved"
      class="btn-group"
      role="group">
      <button
        @click="jumpToFirstDiscussion"
        v-tooltip
        title="Jump to first unresolved discussion"
        data-container="body"
        class="btn btn-default discussion-next-btn">
        <span v-html="nextDiscussionSvg"></span>
      </button>
    </div>
  </div>
</template>
