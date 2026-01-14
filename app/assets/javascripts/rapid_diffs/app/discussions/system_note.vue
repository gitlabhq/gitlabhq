<script>
import { GlIcon } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import NoteAuthor from './note_author.vue';
import TimelineEntryItem from './timeline_entry_item.vue';

export default {
  name: 'SystemNote',
  components: {
    TimeAgoTooltip,
    NoteAuthor,
    TimelineEntryItem,
    GlIcon,
  },
  directives: {
    SafeHtml,
  },
  props: {
    note: {
      type: Object,
      required: true,
    },
    isLastDiscussion: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <timeline-entry-item
    :id="`note_${note.id}`"
    timeline-layout
    :is-last-discussion="isLastDiscussion"
  >
    <template #avatar>
      <div
        class="gl-ml-2 gl-flex gl-h-6 gl-w-6 gl-items-center gl-justify-center gl-rounded-full gl-bg-strong gl-text-subtle"
      >
        <gl-icon name="comment-dots" />
      </div>
    </template>
    <template #content>
      <div class="gl-mt-1 gl-flex gl-flex-wrap gl-gap-3 gl-text-subtle">
        <note-author v-if="note.author" :author="note.author" :show-username="false" />
        <span v-else>{{ __('A deleted user') }}</span>
        <div
          v-safe-html="note.note_html"
          class="system-note-message gl-inline gl-overflow-hidden gl-break-words"
          data-testid="system-note-content"
        ></div>
        <time-ago-tooltip :time="note.created_at" />
      </div>
    </template>
  </timeline-entry-item>
</template>

<style>
.system-note-message {
  p {
    display: inline;
    margin: 0;
  }

  a {
    @apply gl-text-link;
  }

  .gfm-project_member {
    color: var(--gl-link-mention-text-color-default);

    &.current-user {
      color: var(--gl-link-mention-text-color-current);
    }
  }
}
</style>
