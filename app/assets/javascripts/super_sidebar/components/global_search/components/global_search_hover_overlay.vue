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
    class="gl-display-flex gl-justify-content-space-between gl-align-items-center gl-gap-3 gl-min-w-0"
  >
    <span class="gl-display-flex gl-gap-3 gl-flex-grow-1 gl-min-w-0">
      <slot></slot>
    </span>
    <span
      class="show-hover-layover-hint gl-opacity-0 gl-justify-content-end gl-align-items-center gl-display-none gl-sm-display-flex"
    >
      <span class="gl-text-gray-700 gl-white-space-nowrap" data-testid="overlay-message">
        <gl-sprintf :message="textMessage">
          <template #kbd="{ content }">
            <kbd class="gl-font-base gl-pb-3 vertical-align-normalization gl-vertical-align-middle">
              {{ content }}
            </kbd>
          </template>
        </gl-sprintf>
      </span>
    </span>
  </span>
</template>
