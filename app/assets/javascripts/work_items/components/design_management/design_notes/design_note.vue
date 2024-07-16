<script>
import { GlAvatar, GlAvatarLink, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __ } from '~/locale';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { TYPE_COMMENT } from '~/import/constants';
import { findNoteId } from '../utils';

export default {
  i18n: {
    editCommentLabel: __('Edit comment'),
    moreActionsLabel: __('More actions'),
    deleteCommentText: __('Delete comment'),
    copyCommentLink: __('Copy link'),
  },
  components: {
    GlAvatar,
    GlAvatarLink,
    GlLink,
    ImportedBadge,
    TimeAgoTooltip,
    TimelineEntryItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  props: {
    note: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isEditing: false,
    };
  },
  computed: {
    author() {
      return this.note.author || {};
    },
    hasAuthor() {
      return !isEmpty(this.author);
    },
    authorId() {
      return getIdFromGraphQLId(this.author.id);
    },
    noteAnchorId() {
      return findNoteId(this.note.id);
    },
    isImported() {
      return this.note.imported;
    },
  },
  TYPE_COMMENT,
};
</script>

<template>
  <timeline-entry-item :id="`note_${noteAnchorId}`" class="design-note note-form">
    <gl-avatar-link
      :href="author.webUrl"
      :data-user-id="authorId"
      :data-username="author.username"
      class="gl-float-left gl-mr-3 link-inherit-color js-user-link"
    >
      <gl-avatar
        :size="32"
        :src="author.avatarUrl"
        :entity-name="author.username"
        :alt="author.username"
      />
    </gl-avatar-link>

    <div class="gl-flex gl-justify-between">
      <div>
        <gl-link
          v-if="hasAuthor"
          v-once
          :href="author.webUrl"
          class="js-user-link link-inherit-color"
          data-testid="user-link"
          :data-user-id="authorId"
          :data-username="author.username"
        >
          <span class="note-header-author-name gl-font-bold">{{ author.name }}</span>
          <span v-if="author.status_tooltip_html" v-safe-html="author.status_tooltip_html"></span>
          <span class="note-headline-light">@{{ author.username }}</span>
        </gl-link>
        <span v-else>{{ __('A deleted user') }}</span>
        <span class="note-headline-light note-headline-meta">
          <span class="system-note-message"> <slot></slot> </span>
          <gl-link
            class="note-timestamp system-note-separator gl-inline-block gl-mb-2 gl-text-sm link-inherit-color"
            :href="`#note_${noteAnchorId}`"
          >
            <time-ago-tooltip :time="note.createdAt" tooltip-placement="bottom" />
          </gl-link>
          <imported-badge v-if="isImported" :importable-type="$options.TYPE_COMMENT" size="sm" />
        </span>
      </div>
      <div class="gl-flex gl-items-start -gl-mt-2 -gl-mr-2">
        <slot name="resolve-discussion"></slot>
      </div>
    </div>
    <template v-if="!isEditing">
      <div v-safe-html="note.bodyHtml" class="note-text md" data-testid="note-text"></div>
      <slot name="resolved-status"></slot>
    </template>
  </timeline-entry-item>
</template>
