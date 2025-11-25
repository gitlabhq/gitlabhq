<script>
import { GlBadge, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import { isGid, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  name: 'NoteHeader',
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
      default: null,
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
      type: String,
      required: false,
      default: null,
    },
    isUpdating: {
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
      default: undefined,
    },
  },
  computed: {
    authorId() {
      return getIdFromGraphQLId(this.author.id);
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
    internalNoteTooltip() {
      return s__('Notes|This internal note will always remain confidential');
    },
  },
};
</script>

<template>
  <div class="note-header-info">
    <template v-if="author">
      <a
        :href="author.path || author.webUrl"
        class="author-name-link js-user-link gl-overflow-hidden gl-break-words"
        :data-user-id="authorId"
        :data-username="author.username"
      >
        <span
          class="note-header-author-name gl-font-bold"
          data-testid="author-name"
          v-text="author.name"
        ></span>
        <span
          v-if="!isSystemNote"
          class="author-username -gl-m-2 gl-mr-0 gl-hidden gl-truncate !gl-whitespace-nowrap gl-p-2 @md/panel:gl-inline"
        >
          <span class="author-username-link focus:gl-focus">
            <span class="note-headline-light">@{{ author.username }} </span>
          </span>
          <slot name="note-header-info"></slot>
        </span>
      </a>
    </template>
    <span v-else>{{ __('A deleted user') }}</span>
    <span class="note-headline-light note-headline-meta">
      <span
        v-if="$scopedSlots.default"
        class="system-note-message"
        :class="!isSystemNote && 'md:-gl-ml-2'"
        data-testid="system-note-content"
      >
        <slot></slot>
      </span>
      <template v-if="createdAt">
        <span class="system-note-separator">
          <template v-if="actionText">{{ actionText }}</template>
        </span>
        <time-ago-tooltip
          v-if="noteTimestampLink"
          :href="noteTimestampLink"
          class="note-timestamp system-note-separator"
          :time="createdAt"
          tooltip-placement="bottom"
        />
        <time-ago-tooltip v-else :time="createdAt" tooltip-placement="bottom" />
      </template>
      <template v-if="isImported">
        <span v-if="isSystemNote">&middot;</span>
        <imported-badge :text-only="isSystemNote" />
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
        v-if="isUpdating"
        size="sm"
        class="editing-spinner"
        :label="__('Comment is being updated')"
      />
    </span>
  </div>
</template>
