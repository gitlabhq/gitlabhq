<script>
/**
 * Common component to render a placeholder note and user information.
 *
 * This component needs to be used with a vuex store.
 * That vuex store needs to have a `getUserData` getter that contains
 * {
 *   path: String,
 *   avatar_url: String,
 *   name: String,
 *   username: String,
 * }
 *
 * @example
 * <placeholder-note
 *   :note="{body: 'This is a note'}"
 *   />
 */
import { GlAvatarLink, GlAvatar } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
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
  props: {
    note: {
      type: Object,
      required: true,
    },
    line: {
      type: Object,
      required: false,
      default: null,
    },
    isOverviewTab: {
      type: Boolean,
      required: false,
      default: false,
    },
    internalNote: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapGetters(['getUserData']),
    renderedNote() {
      return renderMarkdown(this.note.body);
    },
    internalNoteClass() {
      return {
        'internal-note': this.internalNote,
      };
    },
  },
};
</script>

<template>
  <timeline-entry-item
    class="note note-wrapper note-comment being-posted fade-in-half"
    :class="internalNoteClass"
  >
    <div class="timeline-avatar gl-float-left">
      <gl-avatar-link :href="getUserData.path">
        <gl-avatar
          :src="getUserData.avatar_url"
          :entity-name="getUserData.username"
          :alt="getUserData.name"
          :size="32"
        />
      </gl-avatar-link>
    </div>
    <div ref="note" :class="{ discussion: !note.individual_note }" class="timeline-content">
      <div class="note-header">
        <div class="note-header-info">
          <a :href="getUserData.path">
            <span class="gl-hidden gl-font-bold sm:gl-inline-block">{{ getUserData.name }}</span>
            <span class="note-headline-light">@{{ getUserData.username }}</span>
          </a>
        </div>
      </div>
      <div class="timeline-discussion-body">
        <div class="note-body">
          <div v-safe-html="renderedNote" class="note-text md"></div>
        </div>
      </div>
    </div>
  </timeline-entry-item>
</template>
