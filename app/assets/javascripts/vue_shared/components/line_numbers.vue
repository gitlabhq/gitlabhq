<script>
import { GlIcon, GlLink } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
    GlLink,
  },
  props: {
    lines: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      currentlyHighlightedLine: null,
    };
  },
  mounted() {
    this.scrollToLine();
  },
  methods: {
    scrollToLine(hash = window.location.hash) {
      const lineToHighlight = hash && this.$el.querySelector(hash);

      if (!lineToHighlight) {
        return;
      }

      if (this.currentlyHighlightedLine) {
        this.currentlyHighlightedLine.classList.remove('hll');
      }

      lineToHighlight.classList.add('hll');
      this.currentlyHighlightedLine = lineToHighlight;
      lineToHighlight.scrollIntoView({ behavior: 'smooth', block: 'center' });
    },
  },
};
</script>
<template>
  <div class="line-numbers">
    <gl-link
      v-for="line in lines"
      :id="`L${line}`"
      :key="line"
      class="diff-line-num"
      :href="`#L${line}`"
      :data-line-number="line"
      @click="scrollToLine(`#L${line}`)"
    >
      <gl-icon :size="12" name="link" />
      {{ line }}
    </gl-link>
  </div>
</template>
