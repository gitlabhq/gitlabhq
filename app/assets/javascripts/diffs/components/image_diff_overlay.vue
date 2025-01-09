<script>
import { isArray } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters } from 'vuex';
import imageDiffMixin from 'ee_else_ce/diffs/mixins/image_diff';
import DesignNotePin from '~/vue_shared/components/design_management/design_note_pin.vue';

function calcPercent(pos, renderedSize) {
  return (100 * pos) / renderedSize;
}

export default {
  name: 'ImageDiffOverlay',
  components: {
    DesignNotePin,
  },
  mixins: [imageDiffMixin],
  props: {
    discussions: {
      type: [Array, Object],
      required: true,
    },
    fileHash: {
      type: String,
      required: true,
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
    renderedWidth: {
      type: Number,
      required: true,
    },
    renderedHeight: {
      type: Number,
      required: true,
    },
  },
  computed: {
    ...mapGetters('diffs', ['getDiffFileByHash', 'getCommentFormForDiffFile']),
    currentCommentForm() {
      return this.getCommentFormForDiffFile(this.fileHash);
    },
    allDiscussions() {
      return isArray(this.discussions) ? this.discussions : [this.discussions];
    },
  },
  methods: {
    ...mapActions('diffs', ['openDiffFileCommentForm']),
    getImageDimensions() {
      return {
        width: Math.round(this.$parent.width),
        height: Math.round(this.$parent.height),
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
    clickedImage(x, y) {
      const { width, height } = this.getImageDimensions();
      const xPercent = calcPercent(x, this.renderedWidth);
      const yPercent = calcPercent(y, this.renderedHeight);

      this.openDiffFileCommentForm({
        fileHash: this.fileHash,
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
      <span class="sr-only"> {{ __('Add image comment') }} </span>
    </button>

    <design-note-pin
      v-for="(discussion, index) in allDiscussions"
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
      @click="clickedToggle(discussion)"
    />

    <design-note-pin
      v-if="canComment && currentCommentForm"
      :position="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
        left: `${currentCommentForm.xPercent}%`,
        top: `${currentCommentForm.yPercent}%`,
      } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
    />
  </div>
</template>
