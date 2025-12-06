<script>
import SafeHtml from '~/vue_shared/directives/safe_html';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import NoteAuthor from './note_author.vue';

export default {
  name: 'SystemNote',
  components: {
    TimeAgoTooltip,
    NoteAuthor,
    TimelineEntryItem,
  },
  directives: {
    SafeHtml,
  },
  props: {
    note: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <timeline-entry-item :id="`note_${note.id}`">
    <div class="gl-flex gl-gap-6 gl-px-6">
      <div
        class="gl-relative gl-top-[calc(0.5em-1px)] gl-h-3 gl-w-3 gl-rounded-full gl-border-2 gl-border-solid gl-border-subtle gl-bg-[var(--gl-status-neutral-icon-color)]"
      ></div>
      <div class="gl-flex gl-flex-wrap gl-gap-3 gl-text-subtle">
        <note-author v-if="note.author" :author="note.author" :show-username="false" />
        <span v-else>{{ __('A deleted user') }}</span>
        <div
          v-safe-html="note.note_html"
          class="system-note-message gl-inline gl-overflow-hidden gl-break-words"
          data-testid="system-note-content"
        ></div>
        <time-ago-tooltip :time="note.created_at" />
      </div>
    </div>
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
