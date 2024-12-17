<script>
import { GlLoadingIcon, GlTooltipDirective, GlBadge } from '@gitlab/ui';
import { s__ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { getIdFromGid } from '../utils';

export default {
  name: 'NoteHeader',
  components: {
    GlLoadingIcon,
    TimeAgoTooltip,
    GlBadge,
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
    showSpinner: {
      type: Boolean,
      required: false,
      default: false,
    },
    isInternalNote: {
      type: Boolean,
      required: false,
      default: false,
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
      return getIdFromGid(this.author?.id);
    },
    authorHref() {
      const { author } = this;
      return author.path || author.webUrl;
    },
    authorName() {
      return this.isServiceDeskEmailParticipant ? this.emailParticipant : this.author.name;
    },
    isServiceDeskEmailParticipant() {
      return (
        !this.isInternalNote && this.author.username === 'support-bot' && this.emailParticipant
      );
    },
    internalNoteTooltip() {
      return s__('Notes|This internal note will always remain confidential');
    },
    dynamicClasses() {
      return {
        authorLink: {
          hover: this.isUsernameLinkHovered,
          'text-underline': this.isUsernameLinkHovered,
        },
      };
    },
  },
  methods: {
    handleUsernameMouseEnter() {
      this.isUsernameLinkHovered = true;
    },
    handleUsernameMouseLeave() {
      this.isUsernameLinkHovered = false;
    },
  },
};
</script>
<template>
  <div class="note-header-info">
    <template v-if="author.id">
      <span
        v-if="emailParticipant"
        class="note-header-author-name gl-font-bold"
        data-testid="wiki-note-author-name"
        v-text="authorName"
      >
      </span>
      <a
        v-else
        ref="authorNameLink"
        :href="authorHref"
        :class="dynamicClasses.authorLink"
        class="author-name-link js-user-link gl-overflow-hidden gl-break-words"
        data-testid="wiki-note-author-name-link"
        :data-user-id="authorId"
        :data-username="author.username"
      >
        <span
          class="note-header-author-name gl-font-bold"
          data-testid="wiki-note-author-name"
          v-text="authorName"
        ></span>
      </a>
      <span v-if="!emailParticipant" class="text-nowrap author-username gl-truncate">
        <a
          ref="authorUsernameLink"
          class="author-username-link"
          data-testid="wiki-note-author-username-link"
          :href="authorHref"
          @mouseenter="handleUsernameMouseEnter"
          @mouseleave="handleUsernameMouseLeave"
        >
          <span data-testid="wiki-note-username" class="note-headline-light md:gl-inline"
            >@{{ author.username }}</span
          >
        </a>
        <slot name="note-header-info"></slot>
      </span>
      <span v-else-if="emailParticipant" class="note-headline-light">{{
        __('(external participant)')
      }}</span>
    </template>
    <span v-else>{{ __('A deleted user') }}</span>
    <span class="note-headline-light note-healine-meta">
      <template v-if="createdAt">
        <time-ago-tooltip ref="noteTimestamp" :time="createdAt" tooltip-placement="bottom" />
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
      <gl-loading-icon
        v-if="showSpinner"
        ref="spinner"
        size="sm"
        class="gl-ml-3 gl-inline-block"
        :label="__('Comment is being updated')"
      />
    </span>
  </div>
</template>
