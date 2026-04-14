<script>
import { GlBadge, GlLoadingIcon, GlTooltipDirective, GlAvatarLink, GlAvatar } from '@gitlab/ui';
import { isGid, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { withLinkedFileUrlParams } from '~/rapid_diffs/utils/linked_file';
import NoteAuthor from './note_author.vue';

export default {
  name: 'NoteHeader',
  components: {
    ImportedBadge,
    TimeAgoTooltip,
    GlBadge,
    GlLoadingIcon,
    GlAvatarLink,
    GlAvatar,
    NoteAuthor,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    filePaths: {
      default: null,
    },
  },
  props: {
    showAvatar: {
      type: Boolean,
      required: false,
      default: true,
    },
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
    noteId: {
      type: String,
      required: false,
      default: null,
    },
    isUpdating: {
      type: Boolean,
      required: false,
      default: false,
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
    resolvedNoteId() {
      if (!this.noteId) return null;
      let { noteId } = this;
      if (isGid(noteId)) noteId = getIdFromGraphQLId(noteId);
      return noteId;
    },
    noteFragment() {
      if (!this.resolvedNoteId) return null;
      return `note_${this.resolvedNoteId}`;
    },
    noteTimestampLink() {
      if (this.noteUrl) return this.noteUrl;

      if (!this.noteFragment) return undefined;

      if (this.filePaths) {
        return withLinkedFileUrlParams(window.location.href, {
          oldPath: this.filePaths.oldPath,
          newPath: this.filePaths.newPath,
          hash: this.noteFragment,
        }).toString();
      }

      return `#${this.noteFragment}`;
    },
    internalNoteTooltip() {
      return s__('Notes|This internal note will always remain confidential');
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-min-w-0 gl-flex-wrap gl-items-center gl-gap-3">
    <template v-if="author">
      <span v-if="showAvatar" class="gl-flex">
        <gl-avatar-link
          :href="author.path"
          :data-user-id="authorId"
          :data-username="author.username"
          class="js-user-link"
        >
          <gl-avatar
            :src="author.avatar_url"
            :entity-name="author.username"
            :alt="author.name"
            :size="24"
          />
          <slot name="avatar-badge"></slot>
        </gl-avatar-link>
      </span>
      <note-author :author="author" />
    </template>
    <span v-else>{{ __('A deleted user') }}</span>
    <span class="gl-flex gl-flex-wrap gl-items-center gl-gap-1 gl-text-subtle">
      <template v-if="createdAt">
        <span></span>
        <time-ago-tooltip
          v-if="noteTimestampLink"
          :href="noteTimestampLink"
          class="gl-text-subtle hover:gl-text-link"
          :time="createdAt"
          tooltip-placement="bottom"
        />
        <time-ago-tooltip v-else :time="createdAt" tooltip-placement="bottom" />
      </template>
      <slot name="badge"></slot>
      <imported-badge v-if="isImported" />
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
        class="gl-ml-2"
        :label="__('Comment is being updated')"
      />
    </span>
  </div>
</template>
