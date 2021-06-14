<script>
import { __ } from '~/locale';
import { ACTIVE_DISCUSSION_SOURCE_TYPES } from '../constants';
import updateActiveDiscussionMutation from '../graphql/mutations/update_active_discussion.mutation.graphql';
import activeDiscussionQuery from '../graphql/queries/active_discussion.query.graphql';
import DesignNotePin from './design_note_pin.vue';

export default {
  name: 'DesignOverlay',
  components: {
    DesignNotePin,
  },
  props: {
    dimensions: {
      type: Object,
      required: true,
    },
    position: {
      type: Object,
      required: true,
    },
    notes: {
      type: Array,
      required: false,
      default: () => [],
    },
    currentCommentForm: {
      type: Object,
      required: false,
      default: null,
    },
    disableCommenting: {
      type: Boolean,
      required: false,
      default: false,
    },
    resolvedDiscussionsExpanded: {
      type: Boolean,
      required: true,
    },
  },
  apollo: {
    activeDiscussion: {
      query: activeDiscussionQuery,
    },
  },
  data() {
    return {
      movingNoteNewPosition: null,
      movingNoteStartPosition: null,
      activeDiscussion: {},
    };
  },
  computed: {
    overlayStyle() {
      const cursor = this.disableCommenting ? 'unset' : undefined;

      return {
        cursor,
        width: `${this.dimensions.width}px`,
        height: `${this.dimensions.height}px`,
        ...this.position,
      };
    },
    isMovingCurrentComment() {
      return Boolean(this.movingNoteStartPosition && !this.movingNoteStartPosition.noteId);
    },
    currentCommentPositionStyle() {
      return this.isMovingCurrentComment && this.movingNoteNewPosition
        ? this.getNotePositionStyle(this.movingNoteNewPosition)
        : this.getNotePositionStyle(this.currentCommentForm);
    },
    visibleNotes() {
      if (this.resolvedDiscussionsExpanded) {
        return this.notes;
      }

      return this.notes.filter((note) => !note.resolved);
    },
  },
  methods: {
    setNewNoteCoordinates({ x, y }) {
      this.$emit('openCommentForm', { x, y });
    },
    getNoteRelativePosition(position) {
      const { x, y, width, height } = position;
      const widthRatio = this.dimensions.width / width;
      const heightRatio = this.dimensions.height / height;
      return {
        left: Math.round(x * widthRatio),
        top: Math.round(y * heightRatio),
      };
    },
    getNotePositionStyle(position) {
      const { left, top } = this.getNoteRelativePosition(position);
      return {
        left: `${left}px`,
        top: `${top}px`,
      };
    },
    getMovingNotePositionDelta(e) {
      let deltaX = 0;
      let deltaY = 0;

      if (this.movingNoteStartPosition) {
        const { clientX, clientY } = this.movingNoteStartPosition;
        deltaX = e.clientX - clientX;
        deltaY = e.clientY - clientY;
      }

      return {
        deltaX,
        deltaY,
      };
    },
    isMovingNote(noteId) {
      const movingNoteId = this.movingNoteStartPosition?.noteId;
      return Boolean(movingNoteId && movingNoteId === noteId);
    },
    canMoveNote(note) {
      const { userPermissions } = note;
      const { repositionNote } = userPermissions || {};

      return Boolean(repositionNote);
    },
    isPositionInOverlay(position) {
      const { top, left } = this.getNoteRelativePosition(position);
      const { height, width } = this.dimensions;

      return top >= 0 && top <= height && left >= 0 && left <= width;
    },
    onNewNoteMove(e) {
      if (!this.isMovingCurrentComment) return;

      const { deltaX, deltaY } = this.getMovingNotePositionDelta(e);
      const x = this.currentCommentForm.x + deltaX;
      const y = this.currentCommentForm.y + deltaY;

      const movingNoteNewPosition = {
        x,
        y,
        width: this.dimensions.width,
        height: this.dimensions.height,
      };

      if (!this.isPositionInOverlay(movingNoteNewPosition)) {
        this.onNewNoteMouseup();
        return;
      }

      this.movingNoteNewPosition = movingNoteNewPosition;
    },
    onExistingNoteMove(e) {
      const note = this.notes.find(({ id }) => id === this.movingNoteStartPosition.noteId);
      if (!note || !this.canMoveNote(note)) return;

      const { position } = note;
      const { width, height } = position;
      const widthRatio = this.dimensions.width / width;
      const heightRatio = this.dimensions.height / height;

      const { deltaX, deltaY } = this.getMovingNotePositionDelta(e);
      const x = position.x * widthRatio + deltaX;
      const y = position.y * heightRatio + deltaY;

      const movingNoteNewPosition = {
        x,
        y,
        width: this.dimensions.width,
        height: this.dimensions.height,
      };

      if (!this.isPositionInOverlay(movingNoteNewPosition)) {
        this.onExistingNoteMouseup();
        return;
      }

      this.movingNoteNewPosition = movingNoteNewPosition;
    },
    onNewNoteMouseup() {
      if (!this.movingNoteNewPosition) return;

      const { x, y } = this.movingNoteNewPosition;
      this.setNewNoteCoordinates({ x, y });
    },
    onExistingNoteMouseup(note) {
      if (!this.movingNoteStartPosition || !this.movingNoteNewPosition) {
        this.updateActiveDiscussion(note.id);
        this.$emit('closeCommentForm');
        return;
      }

      const { x, y } = this.movingNoteNewPosition;
      this.$emit('moveNote', {
        noteId: this.movingNoteStartPosition.noteId,
        discussionId: this.movingNoteStartPosition.discussionId,
        coordinates: { x, y },
      });
    },
    onNoteMousedown({ clientX, clientY }, note) {
      this.movingNoteStartPosition = {
        noteId: note?.id,
        discussionId: note?.discussion.id,
        clientX,
        clientY,
      };
    },
    onOverlayMousemove(e) {
      if (!this.movingNoteStartPosition) return;

      if (this.isMovingCurrentComment) {
        this.onNewNoteMove(e);
      } else {
        this.onExistingNoteMove(e);
      }
    },
    onNoteMouseup(note) {
      if (!this.movingNoteStartPosition) return;

      if (this.isMovingCurrentComment) {
        this.onNewNoteMouseup();
      } else {
        this.onExistingNoteMouseup(note);
      }

      this.movingNoteStartPosition = null;
      this.movingNoteNewPosition = null;
    },
    onAddCommentMouseup({ offsetX, offsetY }) {
      if (this.disableCommenting) return;
      if (this.activeDiscussion.id) {
        this.updateActiveDiscussion();
      }

      this.setNewNoteCoordinates({ x: offsetX, y: offsetY });
    },
    updateActiveDiscussion(id) {
      this.$apollo.mutate({
        mutation: updateActiveDiscussionMutation,
        variables: {
          id,
          source: ACTIVE_DISCUSSION_SOURCE_TYPES.pin,
        },
      });
    },
    isNoteInactive(note) {
      const discussionNotes = note.discussion.notes.nodes || [];

      return (
        this.activeDiscussion.id &&
        !discussionNotes.some(({ id }) => id === this.activeDiscussion.id)
      );
    },
    designPinClass(note) {
      return { inactive: this.isNoteInactive(note), resolved: note.resolved };
    },
  },
  i18n: {
    newCommentButtonLabel: __('Add comment to design'),
  },
};
</script>

<template>
  <div
    class="gl-absolute gl-top-0 gl-left-0 frame"
    :style="overlayStyle"
    @mousemove="onOverlayMousemove"
    @mouseleave="onNoteMouseup"
  >
    <button
      v-show="!disableCommenting"
      type="button"
      role="button"
      :aria-label="$options.i18n.newCommentButtonLabel"
      class="gl-absolute gl-w-full gl-h-full gl-p-0 gl-top-0 gl-left-0 gl-outline-0! btn-transparent gl-hover-cursor-crosshair"
      data-qa-selector="design_image_button"
      @mouseup="onAddCommentMouseup"
    ></button>

    <design-note-pin
      v-for="note in visibleNotes"
      :key="note.id"
      :label="note.index"
      :position="
        isMovingNote(note.id) && movingNoteNewPosition
          ? getNotePositionStyle(movingNoteNewPosition)
          : getNotePositionStyle(note.position)
      "
      :class="designPinClass(note)"
      @mousedown.stop="onNoteMousedown($event, note)"
      @mouseup.stop="onNoteMouseup(note)"
    />

    <design-note-pin
      v-if="currentCommentForm"
      :position="currentCommentPositionStyle"
      @mousedown.stop="onNoteMousedown"
      @mouseup.stop="onNoteMouseup"
    />
  </div>
</template>
