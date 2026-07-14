<script>
import { GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import {
  getStartLineNumber,
  getEndLineNumber,
  getLineClasses,
} from '~/notes/components/multiline_comment_utils';

export default {
  name: 'LineRangeHeadline',
  components: {
    GlSprintf,
  },
  props: {
    lineRange: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    startLineNumber() {
      return getStartLineNumber(this.lineRange);
    },
    endLineNumber() {
      return getEndLineNumber(this.lineRange);
    },
    hasLineRange() {
      return Boolean(this.startLineNumber && this.endLineNumber);
    },
    message() {
      return this.startLineNumber === this.endLineNumber
        ? __('Comment on line %{startLine}')
        : __('Comment on lines %{startLine} to %{endLine}');
    },
  },
  methods: {
    getLineClasses,
  },
};
</script>

<template>
  <div v-if="hasLineRange" class="gl-flex gl-flex-wrap gl-items-center gl-gap-2">
    <gl-sprintf :message="message">
      <template #startLine>
        <span :class="getLineClasses(startLineNumber)">{{ startLineNumber }}</span>
      </template>
      <template #endLine>
        <span :class="getLineClasses(endLineNumber)">{{ endLineNumber }}</span>
      </template>
    </gl-sprintf>
    <slot></slot>
  </div>
</template>
