<script>
import { GlBadge, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import { isGid, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ACTIVITY, TYPE_COMMENT } from '~/import/constants';
import { s__ } from '~/locale';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    ImportedBadge,
    TimeAgoTooltip,
    GlBadge,
    GlLoadingIcon,
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
    noteableType: {
      type: String,
      required: false,
      default: '',
    },
    showSpinner: {
      type: Boolean,
      required: false,
      default: true,
    },
    isInternalNote: {
      type: Boolean,
      required: false,
      default: false,
    },
    isImported: {
      type: Boolean,
      required: false,
      default: false,
    },
    isSystemNote: {
      type: Boolean,
      required: false,
      default: false,
    },
    noteUrl: {
      type: String,
      required: false,
      default: '',
    },
    emailParticipant: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isUsernameLinkHovered: false,
    };
  },
  computed: {
    authorId() {
      return getIdFromGraphQLId(this.author.id);
    },
    authorHref() {
      return this.author.path || this.author.webUrl;
    },
    noteTimestampLink() {
      if (this.noteUrl) return this.noteUrl;

      if (this.noteId) {
        let { noteId } = this;

        if (isGid(noteId)) noteId = getIdFromGraphQLId(noteId);

        return `#note_${noteId}`;
      }

      return undefined;
    },
    hasAuthor() {
      return this.author && Object.keys(this.author).length;
    },
    isServiceDeskEmailParticipant() {
      return (
        !this.isInternalNote && this.author.username === 'support-bot' && this.emailParticipant
      );
    },
    authorLinkClasses() {
      return {
        hover: this.isUsernameLinkHovered,
        'text-underline': this.isUsernameLinkHovered,
        'author-name-link': true,
        'js-user-link': true,
        'gl-overflow-hidden': true,
        'gl-break-words': true,
      };
    },
    authorName() {
      return this.isServiceDeskEmailParticipant ? this.emailParticipant : this.author.name;
    },
    internalNoteTooltip() {
      return s__('Notes|This internal note will always remain confidential');
    },
    importableType() {
      return this.isSystemNote ? TYPE_ACTIVITY : TYPE_COMMENT;
    },
  },
  methods: {
    ...mapActions(['setTargetNoteHash']),
    updateTargetNoteHash() {
      if (this.$store) {
        this.setTargetNoteHash(this.noteTimestampLink);
      }
    },
    handleUsernameMouseEnter() {
      this.$refs.authorNameLink.dispatchEvent(new Event('mouseenter'));
      this.isUsernameLinkHovered = true;
    },
    handleUsernameMouseLeave() {
      this.$refs.authorNameLink.dispatchEvent(new Event('mouseleave'));
      this.isUsernameLinkHovered = false;
    },
  },
};
</script>

<template>
  <div class="note-header-info">
    <template v-if="hasAuthor">
      <span
        v-if="emailParticipant"
        class="note-header-author-name gl-font-bold"
        data-testid="author-name"
        v-text="authorName"
      ></span>
      <a
        v-else
        ref="authorNameLink"
        :href="authorHref"
        :class="authorLinkClasses"
        :data-user-id="authorId"
        :data-username="author.username"
      >
        <span
          class="note-header-author-name gl-font-bold"
          data-testid="author-name"
          v-text="authorName"
        ></span>
      </a>
      <span
        v-if="!isSystemNote && !emailParticipant"
        class="text-nowrap author-username -gl-m-2 gl-truncate gl-p-2"
      >
        <a
          ref="authorUsernameLink"
          class="author-username-link focus:gl-focus"
          :href="authorHref"
          @mouseenter="handleUsernameMouseEnter"
          @mouseleave="handleUsernameMouseLeave"
          ><span class="note-headline-light gl-hidden md:gl-inline">@{{ author.username }}</span>
        </a>
        <slot name="note-header-info"></slot>
      </span>
      <span v-if="emailParticipant" class="note-headline-light">{{
        __('(external participant)')
      }}</span>
    </template>
    <span v-else>{{ __('A deleted user') }}</span>
    <span class="note-headline-light note-headline-meta">
      <span class="system-note-message" data-testid="system-note-content">
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

      <template v-if="isImported">
        <span v-if="isSystemNote">&middot;</span>
        <imported-badge :text-only="isSystemNote" :importable-type="importableType" />
      </template>

      <gl-badge
        v-if="isInternalNote"
        v-gl-tooltip:tooltipcontainer.bottom
        data-testid="internal-note-indicator"
        variant="warning"
        class="gl-ml-2"
        :title="internalNoteTooltip"
      >
        {{ __('Internal note') }}
      </gl-badge>
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
