<script>
import { mapActions } from 'vuex';
import timeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import GitlabTeamMemberBadge from '~/vue_shared/components/user_avatar/badges/gitlab_team_member_badge.vue';

export default {
  components: {
    timeAgoTooltip,
    GitlabTeamMemberBadge,
  },
  props: {
    author: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    createdAt: {
      type: String,
      required: false,
      default: null,
    },
    actionText: {
      type: String,
      required: false,
      default: '',
    },
    noteId: {
      type: [String, Number],
      required: false,
      default: null,
    },
    includeToggle: {
      type: Boolean,
      required: false,
      default: false,
    },
    expanded: {
      type: Boolean,
      required: false,
      default: true,
    },
    showSpinner: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    toggleChevronClass() {
      return this.expanded ? 'fa-chevron-up' : 'fa-chevron-down';
    },
    noteTimestampLink() {
      return this.noteId ? `#note_${this.noteId}` : undefined;
    },
    hasAuthor() {
      return this.author && Object.keys(this.author).length;
    },
    showGitlabTeamMemberBadge() {
      return this.author?.is_gitlab_employee;
    },
  },
  methods: {
    ...mapActions(['setTargetNoteHash']),
    handleToggle() {
      this.$emit('toggleHandler');
    },
    updateTargetNoteHash() {
      if (this.$store) {
        this.setTargetNoteHash(this.noteTimestampLink);
      }
    },
  },
};
</script>

<template>
  <div class="note-header-info">
    <div v-if="includeToggle" ref="discussionActions" class="discussion-actions">
      <button
        class="note-action-button discussion-toggle-button js-vue-toggle-button"
        type="button"
        @click="handleToggle"
      >
        <i ref="chevronIcon" :class="toggleChevronClass" class="fa" aria-hidden="true"></i>
        {{ __('Toggle thread') }}
      </button>
    </div>
    <template v-if="hasAuthor">
      <a
        v-once
        :href="author.path"
        class="js-user-link"
        :data-user-id="author.id"
        :data-username="author.username"
      >
        <slot name="note-header-info"></slot>
        <span class="note-header-author-name bold">{{ author.name }}</span>
        <span v-if="author.status_tooltip_html" v-html="author.status_tooltip_html"></span>
        <span class="note-headline-light">@{{ author.username }}</span>
      </a>
      <gitlab-team-member-badge v-if="showGitlabTeamMemberBadge" />
    </template>
    <span v-else>{{ __('A deleted user') }}</span>
    <span class="note-headline-light note-headline-meta">
      <span class="system-note-message"> <slot></slot> </span>
      <template v-if="createdAt">
        <span ref="actionText" class="system-note-separator">
          <template v-if="actionText">{{ actionText }}</template>
        </span>
        <a
          v-if="noteTimestampLink"
          ref="noteTimestampLink"
          :href="noteTimestampLink"
          class="note-timestamp system-note-separator"
          @click="updateTargetNoteHash"
        >
          <time-ago-tooltip :time="createdAt" tooltip-placement="bottom" />
        </a>
        <time-ago-tooltip v-else ref="noteTimestamp" :time="createdAt" tooltip-placement="bottom" />
      </template>
      <slot name="extra-controls"></slot>
      <i
        v-if="showSpinner"
        ref="spinner"
        class="fa fa-spinner fa-spin editing-spinner"
        :aria-label="__('Comment is being updated')"
        aria-hidden="true"
      ></i>
    </span>
  </div>
</template>
