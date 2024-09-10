<script>
import { GlFormSelect, GlSprintf } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import { getSymbol, getLineClasses } from './multiline_comment_utils';

export default {
  components: { GlFormSelect, GlSprintf },
  props: {
    lineRange: {
      type: Object,
      required: false,
      default: null,
    },
    line: {
      type: Object,
      required: true,
    },
    commentLineOptions: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      commentLineStart: {},
      commentLineEndType: this.lineRange?.end?.line_type || this.line.type,
    };
  },
  computed: {
    lineNumber() {
      return this.commentLineOptions[this.commentLineOptions.length - 1].text;
    },
  },
  created() {
    const line = this.lineRange?.start || this.line;

    this.commentLineStart = {
      line_code: line.line_code,
      type: line.type,
      old_line: line.old_line,
      new_line: line.new_line,
    };

    this.highlightSelection();
  },
  destroyed() {
    this.setSelectedCommentPosition();
  },
  methods: {
    ...mapActions(['setSelectedCommentPosition']),
    getSymbol({ type }) {
      return getSymbol(type);
    },
    getLineClasses(line) {
      return getLineClasses(line);
    },
    updateCommentLineStart(value) {
      this.commentLineStart = value;
      this.$emit('input', value);
      this.highlightSelection();
    },
    highlightSelection() {
      const { line_code, new_line, old_line, type } = this.line;
      const updatedLineRange = {
        start: { ...this.commentLineStart },
        end: { line_code, new_line, old_line, type },
      };

      this.setSelectedCommentPosition(updatedLineRange);
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-wrap gl-items-center gl-gap-2">
    <gl-sprintf
      :message="
        s__('MergeRequestDiffs|Commenting on lines %{selectStart}start%{selectEnd} to %{end}')
      "
    >
      <template #select>
        <label for="comment-line-start" class="sr-only">{{
          s__('MergeRequestDiffs|Select comment starting line')
        }}</label>
        <gl-form-select
          id="comment-line-start"
          :value="commentLineStart"
          :options="commentLineOptions"
          width="sm"
          class="gl-w-auto"
          @change="updateCommentLineStart"
        />
      </template>
      <template #end>
        <span :class="getLineClasses(line)">
          {{ lineNumber }}
        </span>
      </template>
    </gl-sprintf>
  </div>
</template>
