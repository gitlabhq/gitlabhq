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
  <span class="gl-flex gl-min-w-0 gl-items-center gl-justify-between gl-gap-3">
    <span class="gl-flex gl-min-w-0 gl-grow gl-gap-3">
      <slot></slot>
    </span>
    <span
      class="show-hover-layover-hint gl-hidden gl-items-center gl-justify-end gl-opacity-0 sm:gl-flex"
    >
      <span class="gl-whitespace-nowrap gl-text-default" data-testid="overlay-message">
        <gl-sprintf :message="textMessage">
          <template #kbd="{ content }">
            <kbd class="vertical-align-normalization gl-pb-3 gl-align-middle gl-text-base">
              {{ content }}
            </kbd>
          </template>
        </gl-sprintf>
      </span>
    </span>
  </span>
</template>
