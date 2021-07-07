<script>
/* eslint-disable vue/no-v-html */
import { GlIcon, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import { mapActions } from 'vuex';
import timeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserNameWithStatus from '../../sidebar/components/assignees/user_name_with_status.vue';

export default {
  components: {
    timeAgoTooltip,
    GitlabTeamMemberBadge: () =>
      import('ee_component/vue_shared/components/user_avatar/badges/gitlab_team_member_badge.vue'),
    GlIcon,
    GlLoadingIcon,
    UserNameWithStatus,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
    isConfidential: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isUsernameLinkHovered: false,
      emojiTitle: '',
      authorStatusHasTooltip: false,
    };
  },
  computed: {
    toggleChevronIconName() {
      return this.expanded ? 'chevron-up' : 'chevron-down';
    },
    noteTimestampLink() {
      return this.noteId ? `#note_${this.noteId}` : undefined;
    },
    hasAuthor() {
      return this.author && Object.keys(this.author).length;
    },
    authorLinkClasses() {
      return {
        hover: this.isUsernameLinkHovered,
        'text-underline': this.isUsernameLinkHovered,
        'author-name-link': true,
        'js-user-link': true,
      };
    },
    authorStatus() {
      if (this.author?.show_status) {
        return this.author.status_tooltip_html;
      }
      return false;
    },
    emojiElement() {
      return this.$refs?.authorStatus?.querySelector('gl-emoji');
    },
    authorName() {
      return this.author.name;
    },
  },
  mounted() {
    this.emojiTitle = this.emojiElement ? this.emojiElement.getAttribute('title') : '';

    const authorStatusTitle = this.$refs?.authorStatus
      ?.querySelector('.user-status-emoji')
      ?.getAttribute('title');
    this.authorStatusHasTooltip = authorStatusTitle && authorStatusTitle !== '';
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
    removeEmojiTitle() {
      this.emojiElement.removeAttribute('title');
    },
    addEmojiTitle() {
      this.emojiElement.setAttribute('title', this.emojiTitle);
    },
    handleUsernameMouseEnter() {
      this.$refs.authorNameLink.dispatchEvent(new Event('mouseenter'));
      this.isUsernameLinkHovered = true;
    },
    handleUsernameMouseLeave() {
      this.$refs.authorNameLink.dispatchEvent(new Event('mouseleave'));
      this.isUsernameLinkHovered = false;
    },
    userAvailability(selectedAuthor) {
      return selectedAuthor?.availability || '';
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
        <gl-icon ref="chevronIcon" :name="toggleChevronIconName" />
        {{ __('Toggle thread') }}
      </button>
    </div>
    <template v-if="hasAuthor">
      <a
        ref="authorNameLink"
        :href="author.path"
        :class="authorLinkClasses"
        :data-user-id="author.id"
        :data-username="author.username"
      >
        <slot name="note-header-info"></slot>
        <user-name-with-status
          :name="authorName"
          :availability="userAvailability(author)"
          container-classes="note-header-author-name gl-font-weight-bold"
        />
      </a>
      <span
        v-if="authorStatus"
        ref="authorStatus"
        v-on="
          authorStatusHasTooltip ? { mouseenter: removeEmojiTitle, mouseleave: addEmojiTitle } : {}
        "
        v-html="authorStatus"
      ></span>
      <span class="text-nowrap author-username">
        <a
          ref="authorUsernameLink"
          class="author-username-link"
          :href="author.path"
          @mouseenter="handleUsernameMouseEnter"
          @mouseleave="handleUsernameMouseLeave"
          ><span class="note-headline-light">@{{ author.username }}</span>
        </a>
        <gitlab-team-member-badge v-if="author && author.is_gitlab_employee" />
      </span>
    </template>
    <span v-else>{{ __('A deleted user') }}</span>
    <span class="note-headline-light note-headline-meta">
      <span class="system-note-message" data-qa-selector="system_note_content">
        <slot></slot>
      </span>
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
      <gl-icon
        v-if="isConfidential"
        v-gl-tooltip:tooltipcontainer.bottom
        data-testid="confidentialIndicator"
        name="eye-slash"
        :size="16"
        :title="s__('Notes|This comment is confidential and only visible to project members')"
        class="gl-ml-1 gl-text-orange-700 align-middle"
      />
      <slot name="extra-controls"></slot>
      <gl-loading-icon
        v-if="showSpinner"
        ref="spinner"
        size="sm"
        class="editing-spinner"
        :label="__('Comment is being updated')"
      />
    </span>
  </div>
</template>
