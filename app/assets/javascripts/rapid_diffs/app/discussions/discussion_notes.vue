<script>
import { GlSprintf } from '@gitlab/ui';
import {
  getStartLineNumber,
  getEndLineNumber,
  getLineClasses,
} from '~/notes/components/multiline_comment_utils';
import ToggleRepliesWidget from '~/notes/components/toggle_replies_widget.vue';
import DraftNote from './draft_note.vue';
import SystemNote from './system_note.vue';
import NoteableNote from './noteable_note.vue';

export default {
  name: 'DiscussionNotes',
  components: {
    GlSprintf,
    DraftNote,
    SystemNote,
    NoteableNote,
    ToggleRepliesWidget,
  },
  inject: {
    userPermissions: {
      type: Object,
    },
  },
  props: {
    notes: {
      type: Array,
      required: true,
    },
    expanded: {
      type: Boolean,
      required: false,
      default: true,
    },
    individual: {
      type: Boolean,
      required: false,
      default: false,
    },
    timelineLayout: {
      type: Boolean,
      required: false,
      default: false,
    },
    isLastDiscussion: {
      type: Boolean,
      required: false,
      default: false,
    },
    canResolve: {
      type: Boolean,
      required: false,
      default: false,
    },
    isResolved: {
      type: Boolean,
      required: false,
      default: false,
    },
    isResolving: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    hasReplies() {
      return Boolean(this.replies.length);
    },
    replies() {
      return this.notes.slice(1).filter((note) => !note.isDraft);
    },
    draftReplies() {
      return this.notes.slice(1).filter((note) => note.isDraft);
    },
    firstNote() {
      return this.notes[0];
    },
    lineRange() {
      return this.firstNote.position?.line_range;
    },
    startLineNumber() {
      return getStartLineNumber(this.lineRange);
    },
    endLineNumber() {
      return getEndLineNumber(this.lineRange);
    },
    showMultiLineComment() {
      if (!this.startLineNumber || !this.endLineNumber) return false;

      return this.startLineNumber !== this.endLineNumber;
    },
  },
  methods: {
    getLineClasses,
  },
};
</script>

<template>
  <ul class="gl-list-none gl-p-0">
    <system-note v-if="firstNote.system" :note="firstNote" :is-last-discussion="isLastDiscussion" />
    <noteable-note
      v-else
      :note="firstNote"
      :timeline-layout="timelineLayout"
      :show-reply-button="userPermissions.can_create_note && !individual"
      :is-last-discussion="isLastDiscussion"
      :can-resolve="canResolve"
      :is-resolved="isResolved"
      :is-resolving="isResolving"
      @resolve="$emit('resolve')"
      @noteEdited="$emit('noteEdited', { note: firstNote, value: $event })"
      @startReplying="$emit('startReplying')"
      @startEditing="$emit('startEditing', firstNote)"
      @cancelEditing="$emit('cancelEditing', firstNote)"
    >
      <template v-if="showMultiLineComment" #headline>
        <gl-sprintf :message="__('Comment on lines %{startLine} to %{endLine}')">
          <template #startLine>
            <span :class="getLineClasses(startLineNumber)">{{ startLineNumber }}</span>
          </template>
          <template #endLine>
            <span :class="getLineClasses(endLineNumber)">{{ endLineNumber }}</span>
          </template>
        </gl-sprintf>
      </template>
      <template #avatar-badge>
        <slot name="avatar-badge"></slot>
      </template>
      <template #footer>
        <div
          v-if="hasReplies || draftReplies.length || userPermissions.can_create_note"
          class="gl-m-0 gl-rounded-[var(--content-border-radius)] gl-bg-subtle"
        >
          <ul class="gl-list-none gl-p-0">
            <li v-if="hasReplies" class="gl-border-t gl-px-5" :aria-expanded="expanded">
              <toggle-replies-widget
                tag="div"
                :collapsed="!expanded"
                :replies="replies"
                class="gl-mx-2 !gl-border-0 gl-border-t-subtle !gl-px-0"
                @toggle="$emit('toggleDiscussionReplies')"
              />
            </li>
            <template v-if="expanded">
              <template v-for="note in replies">
                <system-note
                  v-if="note.system"
                  :key="`system-${note.id}`"
                  :note="note"
                  :is-last-discussion="isLastDiscussion"
                />
                <noteable-note
                  v-else
                  :key="note.id"
                  :note="note"
                  :is-last-discussion="isLastDiscussion"
                  @noteEdited="$emit('noteEdited', { note, value: $event })"
                  @startEditing="$emit('startEditing', note)"
                  @cancelEditing="$emit('cancelEditing', note)"
                />
              </template>
              <slot name="footer" :has-replies="hasReplies"></slot>
            </template>
          </ul>
          <draft-note v-for="draft in draftReplies" :key="`draft-${draft.id}`" :draft="draft" />
        </div>
      </template>
    </noteable-note>
  </ul>
</template>
