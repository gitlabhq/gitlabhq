<script>
import { getHighlightIndices, buildSegments } from '~/lib/utils/highlight_indices';

export default {
  name: 'HighlightedText',
  props: {
    text: { type: String, required: true },
    match: { type: String, required: false, default: '' },
    highlightClass: { type: String, required: false, default: '' },
    global: { type: Boolean, required: false, default: false },
  },
  computed: {
    segments() {
      const indices = getHighlightIndices(this.text, this.match, { global: this.global });
      return buildSegments(this.text, indices);
    },
  },
};
</script>

<template>
  <span>
    <template v-for="(segment, i) in segments">
      <span
        v-if="segment.highlight"
        :key="`h-${i}`"
        :class="highlightClass || 'gl-font-bold'"
        data-testid="highlighted-segment"
        >{{ segment.text }}</span
      >
      <span v-else :key="`n-${i}`" data-testid="unhighlighted-segment">{{ segment.text }}</span>
    </template>
  </span>
</template>
