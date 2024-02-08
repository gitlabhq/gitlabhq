<script>
import { GlSprintf } from '@gitlab/ui';

export default {
  name: 'SearchResultHoverLayover',
  components: {
    GlSprintf,
  },
  props: {
    textMessage: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <span
    class="show-hover-layover-hint gl-opacity-0 gl-display-flex gl-justify-content-end gl-align-items-center"
  >
    <span class="gl-pr-2 gl-text-gray-700" data-testid="overlayMessage">
      <gl-sprintf :message="textMessage">
        <template #kbd="{ content }">
          <kbd class="gl-font-base gl-pb-3 vertical-align-normalization gl-vertical-align-middle">{{
            content
          }}</kbd>
        </template>
      </gl-sprintf>
    </span>
  </span>
</template>
