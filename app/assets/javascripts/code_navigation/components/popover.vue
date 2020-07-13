<script>
import { GlButton } from '@gitlab/ui';
import DocLine from './doc_line.vue';

export default {
  components: {
    GlButton,
    DocLine,
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
    definitionPathPrefix: {
      type: String,
      required: true,
    },
    blobPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      offsetLeft: 0,
    };
  },
  computed: {
    isCurrentDefinition() {
      return this.data.definitionLineNumber - 1 === this.position.lineIndex;
    },
    positionStyles() {
      return {
        left: `${this.position.x - this.offsetLeft}px`,
        top: `${this.position.y + this.position.height}px`,
      };
    },
    definitionPath() {
      if (!this.data.definition_path) {
        return null;
      }

      if (this.isDefinitionCurrentBlob) {
        return `#L${this.data.definitionLineNumber}`;
      }

      return `${this.definitionPathPrefix}/${this.data.definition_path}`;
    },
    isDefinitionCurrentBlob() {
      return this.data.definition_path.indexOf(this.blobPath) === 0;
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
    <div class="overflow-auto code-navigation-popover-container">
      <div
        v-for="(hover, index) in data.hover"
        :key="index"
        :class="{ 'border-bottom': index !== data.hover.length - 1 }"
      >
        <pre
          v-if="hover.language"
          ref="code-output"
          :class="$options.colorScheme"
          class="border-0 bg-transparent m-0 code highlight text-wrap"
        ><doc-line v-for="(tokens, tokenIndex) in hover.tokens" :key="tokenIndex" :language="hover.language" :tokens="tokens"/></pre>
        <p v-else ref="doc-output" class="p-3 m-0 gl-font-base">
          {{ hover.value }}
        </p>
      </div>
    </div>
    <div v-if="definitionPath || isCurrentDefinition" class="popover-body border-top">
      <span v-if="isCurrentDefinition" class="gl-font-weight-bold gl-font-base">
        {{ s__('CodeIntelligence|This is the definition') }}
      </span>
      <gl-button
        v-else
        :href="definitionPath"
        :target="isDefinitionCurrentBlob ? null : '_blank'"
        class="w-100"
        variant="default"
        data-testid="go-to-definition-btn"
      >
        {{ __('Go to definition') }}
      </gl-button>
    </div>
  </div>
</template>
