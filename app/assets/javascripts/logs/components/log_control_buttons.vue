<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    scrollUpButtonDisabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    scrollDownButtonDisabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      scrollUpAvailable: Boolean(this.$listeners.scrollUp),
      scrollDownAvailable: Boolean(this.$listeners.scrollDown),
    };
  },
  methods: {
    handleRefreshClick() {
      this.$emit('refresh');
    },
    handleScrollUp() {
      this.$emit('scrollUp');
    },
    handleScrollDown() {
      this.$emit('scrollDown');
    },
  },
};
</script>

<template>
  <div>
    <div
      v-if="scrollUpAvailable"
      v-gl-tooltip
      class="controllers-buttons"
      :title="__('Scroll to top')"
      aria-labelledby="scroll-to-top"
    >
      <gl-button
        id="scroll-to-top"
        class="js-scroll-to-top gl-mr-2 btn-blank"
        :aria-label="__('Scroll to top')"
        :disabled="scrollUpButtonDisabled"
        icon="scroll_up"
        category="primary"
        variant="default"
        @click="handleScrollUp()"
      />
    </div>
    <div
      v-if="scrollDownAvailable"
      v-gl-tooltip
      :disabled="scrollUpButtonDisabled"
      class="controllers-buttons"
      :title="__('Scroll to bottom')"
      aria-labelledby="scroll-to-bottom"
    >
      <gl-button
        id="scroll-to-bottom"
        class="js-scroll-to-bottom gl-mr-2 btn-blank"
        :aria-label="__('Scroll to bottom')"
        :v-if="scrollDownAvailable"
        :disabled="scrollDownButtonDisabled"
        icon="scroll_down"
        category="primary"
        variant="default"
        @click="handleScrollDown()"
      />
    </div>
    <gl-button
      id="refresh-log"
      v-gl-tooltip
      class="js-refresh-log"
      :title="__('Refresh')"
      :aria-label="__('Refresh')"
      icon="retry"
      category="primary"
      variant="default"
      @click="handleRefreshClick"
    />
  </div>
</template>
