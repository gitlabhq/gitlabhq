<script>
import { GlAvatar } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import NoteHeader from '~/notes/components/note_header.vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';

export default {
  name: 'WorkItemNoteReplying',
  components: {
    TimelineEntryItem,
    GlAvatar,
    NoteHeader,
  },
  directives: {
    SafeHtml,
  },
  safeHtmlConfig: {
    ADD_TAGS: ['use', 'gl-emoji', 'copy-code'],
  },
  constantOptions: {
    avatarUrl: window.gon.current_user_avatar_url,
  },
  props: {
    body: {
      type: String,
      required: false,
      default: '',
    },
    isInternalNote: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    author() {
      return {
        avatarUrl: window.gon.current_user_avatar_url,
        id: window.gon.current_user_id,
        name: window.gon.current_user_fullname,
        username: window.gon.current_username,
      };
    },
    entryClass() {
      return {
        'note note-wrapper note-comment being-posted': true,
        'internal-note': this.isInternalNote,
      };
    },
  },
};
</script>

<template>
  <timeline-entry-item :class="entryClass">
    <div class="timeline-avatar gl-float-left">
      <gl-avatar :src="$options.constantOptions.avatarUrl" :size="32" />
    </div>
    <div class="timeline-content" data-testid="note-wrapper">
      <div class="note-header">
        <note-header :author="author" />
      </div>
      <div ref="note-body" class="timeline-discussion-body">
        <div class="note-body">
          <div
            v-safe-html:[$options.safeHtmlConfig]="body"
            class="note-text md"
            data-testid="work-item-note-body"
          ></div>
        </div>
      </div>
    </div>
  </timeline-entry-item>
</template>
