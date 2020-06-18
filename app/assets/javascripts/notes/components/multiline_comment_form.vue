<script>
import { GlFormSelect, GlSprintf } from '@gitlab/ui';
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
      commentLineStart: {
        lineCode: this.lineRange ? this.lineRange.start_line_code : this.line.line_code,
        type: this.lineRange ? this.lineRange.start_line_type : this.line.type,
      },
    };
  },
  methods: {
    getSymbol({ type }) {
      return getSymbol(type);
    },
    getLineClasses(line) {
      return getLineClasses(line);
    },
  },
};
</script>

<template>
  <div>
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
          size="sm"
          class="gl-w-auto gl-vertical-align-baseline"
          @change="$emit('input', $event)"
        />
      </template>
      <template #end>
        <span :class="getLineClasses(line)">
          {{ getSymbol(line) + (line.new_line || line.old_line) }}
        </span>
      </template>
    </gl-sprintf>
  </div>
</template>
