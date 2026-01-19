<script>
import { mapActions, mapState } from 'pinia';
import { isArray } from 'lodash';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import BaseImageDiffOverlay from './base_image_diff_overlay.vue';

export default {
  name: 'ImageDiffOverlay',
  components: {
    BaseImageDiffOverlay,
  },
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
  computed: {
    ...mapState(useLegacyDiffs, ['getCommentFormForDiffFile']),
    allDiscussions() {
      return isArray(this.discussions) ? this.discussions : [this.discussions];
    },
    currentCommentForm() {
      return this.getCommentFormForDiffFile(this.fileHash);
    },
  },
  methods: {
    ...mapActions(useLegacyDiffs, ['toggleFileDiscussion', 'openDiffFileCommentForm']),
    clickedToggle(discussion) {
      this.toggleFileDiscussion(discussion);
    },
    onImageClick(data) {
      this.openDiffFileCommentForm({
        fileHash: this.fileHash,
        ...data,
      });
    },
  },
};
</script>

<template>
  <base-image-diff-overlay
    :discussions="allDiscussions"
    :comment-form="currentCommentForm"
    :can-comment="canComment"
    :show-comment-icon="showCommentIcon"
    :badge-class="badgeClass"
    :should-toggle-discussion="shouldToggleDiscussion"
    :width="width"
    :height="height"
    :rendered-width="renderedWidth"
    :rendered-height="renderedHeight"
    @image-click="onImageClick"
    @pin-click="clickedToggle"
  />
</template>
