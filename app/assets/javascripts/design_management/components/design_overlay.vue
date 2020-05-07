<script>
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
  },
  data() {
    return {
      movingNoteNewPosition: null,
      movingNoteStartPosition: null,
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
      const { adminNote } = userPermissions || {};

      return Boolean(adminNote);
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
      if (!note) return;

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
    onExistingNoteMouseup() {
      if (!this.movingNoteStartPosition || !this.movingNoteNewPosition) return;

      const { x, y } = this.movingNoteNewPosition;
      this.$emit('moveNote', {
        noteId: this.movingNoteStartPosition.noteId,
        discussionId: this.movingNoteStartPosition.discussionId,
        coordinates: { x, y },
      });
    },
    onNoteMousedown({ clientX, clientY }, note) {
      if (note && !this.canMoveNote(note)) return;

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
    onNoteMouseup() {
      if (!this.movingNoteStartPosition) return;

      if (this.isMovingCurrentComment) {
        this.onNewNoteMouseup();
      } else {
        this.onExistingNoteMouseup();
      }

      this.movingNoteStartPosition = null;
      this.movingNoteNewPosition = null;
    },
    onAddCommentMouseup({ offsetX, offsetY }) {
      if (this.disableCommenting) return;

      this.setNewNoteCoordinates({ x: offsetX, y: offsetY });
    },
  },
};
</script>

<template>
  <div
    class="position-absolute image-diff-overlay frame"
    :style="overlayStyle"
    @mousemove="onOverlayMousemove"
    @mouseleave="onNoteMouseup"
  >
    <button
      v-show="!disableCommenting"
      type="button"
      class="btn-transparent position-absolute image-diff-overlay-add-comment w-100 h-100 js-add-image-diff-note-button"
      data-qa-selector="design_image_button"
      @mouseup="onAddCommentMouseup"
    ></button>
    <design-note-pin
      v-for="(note, index) in notes"
      :key="note.id"
      :label="`${index + 1}`"
      :repositioning="isMovingNote(note.id)"
      :position="
        isMovingNote(note.id) && movingNoteNewPosition
          ? getNotePositionStyle(movingNoteNewPosition)
          : getNotePositionStyle(note.position)
      "
      @mousedown.stop="onNoteMousedown($event, note)"
      @mouseup.stop="onNoteMouseup"
    />
    <design-note-pin
      v-if="currentCommentForm"
      :position="currentCommentPositionStyle"
      :repositioning="isMovingCurrentComment"
      @mousedown.stop="onNoteMousedown"
      @mouseup.stop="onNoteMouseup"
    />
  </div>
</template>
