<script>
import { GlAvatarLink, GlAvatar } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { renderMarkdown } from '~/notes/utils';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';

export default {
  name: 'PlaceholderNote',
  directives: { SafeHtml },
  components: {
    GlAvatarLink,
    GlAvatar,
    TimelineEntryItem,
  },
  inject: ['currentUserData'],
  props: {
    note: {
      type: Object,
      required: true,
    },
    internalNote: {
      type: Boolean,
      required: false,
      default: false,
    },
    replyNote: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    userUrl() {
      const { path, web_url: webUrl } = this.currentUserData;
      return path || webUrl;
    },
    renderedNote() {
      return renderMarkdown(this.note.body);
    },
    dynamicClasses() {
      return {
        internalNote: {
          'internal-note': Boolean(this.note.internal),
        },
        noteParent: {
          card: !this.replyNote,
          'gl-ml-7': this.replyNote,
          'gl-ml-8': !this.replyNote,
        },
      };
    },
  },
};
</script>

<template>
  <timeline-entry-item
    data-testid="wiki-placeholder-note-container"
    class="note note-wrapper note-comment being-posted fade-in-half"
    :class="dynamicClasses.internalNote"
  >
    <div class="timeline-avatar gl-float-left">
      <gl-avatar-link :href="userUrl">
        <gl-avatar
          :src="currentUserData.avatar_url"
          :entity-name="currentUserData.username"
          :alt="currentUserData.name"
          :size="32"
        />
      </gl-avatar-link>
    </div>
    <div ref="note" class="gl-mb-5 gl-px-3 gl-py-2" :class="dynamicClasses.noteParent">
      <div data-testid="wiki-placeholder-note-header" class="note-header">
        <div class="note-header-info">
          <a :href="userUrl">
            <span class="gl-hidden gl-font-bold sm:gl-inline-block">{{
              currentUserData.name
            }}</span>
            <span class="note-headline-light">@{{ currentUserData.username }}</span>
          </a>
        </div>
      </div>
      <div data-testid="wiki-placeholder-note-body" class="timeline-discussion-body">
        <div class="note-body">
          <div v-safe-html="renderedNote" class="note-text md"></div>
        </div>
      </div>
    </div>
  </timeline-entry-item>
</template>
