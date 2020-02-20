<script>
import { GlButton } from '@gitlab/ui';

export default {
  components: {
    GlButton,
  },
  props: {
    position: {
      type: Object,
      required: true,
    },
    data: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      offsetLeft: 0,
    };
  },
  computed: {
    positionStyles() {
      return {
        left: `${this.position.x - this.offsetLeft}px`,
        top: `${this.position.y + this.position.height}px`,
      };
    },
  },
  watch: {
    position: {
      handler() {
        this.$nextTick(() => this.updateOffsetLeft());
      },
      deep: true,
      immediate: true,
    },
  },
  methods: {
    updateOffsetLeft() {
      this.offsetLeft = Math.max(
        0,
        this.$el.offsetLeft + this.$el.offsetWidth - window.innerWidth + 20,
      );
    },
  },
  colorScheme: gon?.user_color_scheme,
};
</script>

<template>
  <div
    :style="positionStyles"
    class="popover code-navigation-popover popover-font-size-normal gl-popover bs-popover-bottom show"
  >
    <div :style="{ left: `${offsetLeft}px` }" class="arrow"></div>
    <div v-for="(hover, index) in data.hover" :key="index" class="border-bottom">
      <pre
        v-if="hover.language"
        ref="code-output"
        :class="$options.colorScheme"
        class="border-0 bg-transparent m-0 code highlight"
        v-html="hover.value"
      ></pre>
      <p v-else ref="doc-output" class="p-3 m-0">
        {{ hover.value }}
      </p>
    </div>
    <div v-if="data.definition_url" class="popover-body">
      <gl-button :href="data.definition_url" target="_blank" class="w-100" variant="default">
        {{ __('Go to definition') }}
      </gl-button>
    </div>
  </div>
</template>
