<script>
import { GlIcon } from '@gitlab/ui';
import { isArray } from 'lodash';
import { mapActions, mapGetters } from 'vuex';
import imageDiffMixin from 'ee_else_ce/diffs/mixins/image_diff';

function calcPercent(pos, size, renderedSize) {
  return (((pos / size) * 100) / ((renderedSize / size) * 100)) * 100;
}

export default {
  name: 'ImageDiffOverlay',
  components: {
    GlIcon,
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
      default: 'badge badge-pill',
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
        width: this.$parent.width,
        height: this.$parent.height,
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
      const xPercent = calcPercent(x, width, this.renderedWidth);
      const yPercent = calcPercent(y, height, this.renderedHeight);

      this.openDiffFileCommentForm({
        fileHash: this.fileHash,
        width,
        height,
        x: width * (xPercent / 100),
        y: height * (yPercent / 100),
        xPercent,
        yPercent,
      });
    },
  },
};
</script>

<template>
  <div class="position-absolute w-100 h-100 image-diff-overlay">
    <button
      v-if="canComment"
      type="button"
      class="btn-transparent position-absolute image-diff-overlay-add-comment w-100 h-100 js-add-image-diff-note-button"
      @click="clickedImage($event.offsetX, $event.offsetY)"
    >
      <span class="sr-only"> {{ __('Add image comment') }} </span>
    </button>
    <button
      v-for="(discussion, index) in allDiscussions"
      :key="discussion.id"
      :style="getPosition(discussion)"
      :class="[badgeClass, { 'is-draft': discussion.isDraft }]"
      :disabled="!shouldToggleDiscussion"
      class="js-image-badge"
      type="button"
      :aria-label="__('Show comments')"
      @click="clickedToggle(discussion)"
    >
      <gl-icon v-if="showCommentIcon" name="image-comment-dark" :size="24" />
      <template v-else>
        {{ toggleText(discussion, index) }}
      </template>
    </button>
    <button
      v-if="canComment && currentCommentForm"
      :style="{ left: `${currentCommentForm.xPercent}%`, top: `${currentCommentForm.yPercent}%` }"
      :aria-label="__('Comment form position')"
      class="btn-transparent comment-indicator position-absolute"
      type="button"
    >
      <gl-icon name="image-comment-dark" :size="24" />
    </button>
  </div>
</template>
