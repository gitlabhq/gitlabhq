<script>
import { mapActions, mapGetters } from 'vuex';
import _ from 'underscore';
import imageDiffMixin from 'ee_else_ce/diffs/mixins/image_diff';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'ImageDiffOverlay',
  components: {
    Icon,
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
  },
  computed: {
    ...mapGetters('diffs', ['getDiffFileByHash', 'getCommentFormForDiffFile']),
    currentCommentForm() {
      return this.getCommentFormForDiffFile(this.fileHash);
    },
    allDiscussions() {
      return _.isArray(this.discussions) ? this.discussions : [this.discussions];
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
      const imageWidth = this.getImageDimensions().width;
      const imageHeight = this.getImageDimensions().height;
      const widthRatio = imageWidth / width;
      const heightRatio = imageHeight / height;

      return {
        x: Math.round(x * widthRatio),
        y: Math.round(y * heightRatio),
      };
    },
    getPosition(discussion) {
      const { x, y } = this.getPositionForObject(discussion.position);

      return {
        left: `${x}px`,
        top: `${y}px`,
      };
    },
    clickedImage(x, y) {
      const { width, height } = this.getImageDimensions();

      this.openDiffFileCommentForm({
        fileHash: this.fileHash,
        width,
        height,
        x,
        y,
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
      @click="clickedToggle(discussion)"
    >
      <icon v-if="showCommentIcon" name="image-comment-dark" />
      <template v-else>
        {{ toggleText(discussion, index) }}
      </template>
    </button>
    <button
      v-if="currentCommentForm"
      :style="{
        left: `${currentCommentForm.x}px`,
        top: `${currentCommentForm.y}px`,
      }"
      :aria-label="__('Comment form position')"
      class="btn-transparent comment-indicator"
      type="button"
    >
      <icon name="image-comment-dark" />
    </button>
  </div>
</template>
