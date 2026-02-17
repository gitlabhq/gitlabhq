<script>
import DesignNotePin from '~/vue_shared/components/design_management/design_note_pin.vue';

function calcPercent(pos, renderedSize) {
  return (100 * pos) / renderedSize;
}

export default {
  name: 'BaseImageDiffOverlay',
  components: {
    DesignNotePin,
  },
  props: {
    discussions: {
      type: Array,
      required: true,
    },
    commentForm: {
      type: Object,
      required: false,
      default: null,
    },
    canComment: {
      type: Boolean,
      required: false,
      default: false,
    },
    showCommentIcon: {
      type: Boolean,
      required: false,
      default: false,
    },
    badgeClass: {
      type: String,
      required: false,
      default: '',
    },
    shouldToggleDiscussion: {
      type: Boolean,
      required: false,
      default: true,
    },
    width: {
      type: Number,
      required: true,
    },
    height: {
      type: Number,
      required: true,
    },
    renderedWidth: {
      type: Number,
      required: true,
    },
    renderedHeight: {
      type: Number,
      required: true,
    },
  },
  emits: ['image-click', 'pin-click'],
  computed: {
    nonDraftDiscussions() {
      return this.discussions.filter((d) => !d.isDraft);
    },
    formPosition() {
      return {
        left: `${this.commentForm.xPercent}%`,
        top: `${this.commentForm.yPercent}%`,
      };
    },
  },
  methods: {
    imageDimensions() {
      return {
        width: Math.round(this.width),
        height: Math.round(this.height),
      };
    },
    getPositionForObject(meta) {
      const { x, y, width, height } = meta;

      return {
        x: (x / width) * 100,
        y: (y / height) * 100,
      };
    },
    getPosition(discussion) {
      const { x, y } = this.getPositionForObject(discussion.position);

      return {
        left: `${x}%`,
        top: `${y}%`,
      };
    },
    toggleText(discussion, index) {
      const count = index + 1;

      return discussion.isDraft ? count - this.nonDraftDiscussions.length : count;
    },
    clickedImage(x, y) {
      const { width, height } = this.imageDimensions();
      const xPercent = calcPercent(x, this.renderedWidth);
      const yPercent = calcPercent(y, this.renderedHeight);

      this.$emit('image-click', {
        width,
        height,
        x: Math.round(width * (xPercent / 100)),
        y: Math.round(height * (yPercent / 100)),
        xPercent,
        yPercent,
      });
    },
  },
};
</script>

<template>
  <div class="image-diff-overlay gl-absolute gl-h-full gl-w-full">
    <button
      v-if="canComment"
      type="button"
      class="image-diff-overlay-add-comment js-add-image-diff-note-button gl-absolute gl-h-full gl-w-full gl-border-0 gl-bg-transparent"
      @click="clickedImage($event.offsetX, $event.offsetY)"
    >
      <span class="gl-sr-only"> {{ __('Add image comment') }} </span>
    </button>

    <design-note-pin
      v-for="(discussion, index) in discussions"
      :key="discussion.id"
      :label="showCommentIcon ? null : toggleText(discussion, index)"
      :position="getPosition(discussion)"
      :aria-label="__('Show comments')"
      class="js-image-badge"
      :class="badgeClass"
      :is-draft="discussion.isDraft"
      :is-resolved="discussion.resolved"
      is-on-image
      :disabled="!shouldToggleDiscussion"
      @click="$emit('pin-click', discussion)"
    />

    <design-note-pin v-if="canComment && commentForm" :position="formPosition" />
  </div>
</template>
