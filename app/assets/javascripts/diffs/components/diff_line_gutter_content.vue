<script>
import { MATCH_LINE_TYPE } from '../constants';

export default {
  props: {
    lineType: {
      type: String,
      required: false,
      default: '',
    },
    lineNumber: {
      type: Number,
      required: false,
      default: 0,
    },
    lineCode: {
      type: String,
      required: false,
      default: '',
    },
    linePosition: {
      type: String,
      required: false,
      default: '',
    },
    showCommentButton: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    isMatchLine() {
      return this.lineType === MATCH_LINE_TYPE;
    },
    getLineHref() {
      return `#${this.lineCode}`;
    },
  },
  methods: {
    handleCommentButton() {
      this.$emit('showCommentForm', {
        lineCode: this.lineCode,
        linePosition: this.linePosition,
      });
    },
  },
};
</script>

<template>
  <div>
    <span v-if="isMatchLine">...</span>
    <template
      v-else
    >
      <button
        v-if="showCommentButton"
        @click="handleCommentButton"
        type="button"
        class="add-diff-note js-add-diff-note-button"
        title="Add a comment to this line"
      >
        <i
          aria-hidden="true"
          class="fa fa-comment-o"
        >
        </i>
      </button>
      <a
        v-if="lineNumber"
        :data-linenumber="lineNumber"
        :href="getLineHref"
      >
      </a>
    </template>
  </div>
</template>
