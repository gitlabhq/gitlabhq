<script>
import SafeHtml from '~/vue_shared/directives/safe_html';
import { getPageParamValue, getPageSearchString } from '~/blob/utils';

export default {
  directives: {
    SafeHtml,
  },
  props: {
    number: {
      type: Number,
      required: true,
    },
    content: {
      type: String,
      required: true,
    },
    language: {
      type: String,
      required: true,
    },
    blamePath: {
      type: String,
      required: true,
    },
  },
  computed: {
    pageSearchString() {
      const page = getPageParamValue(this.number);
      return getPageSearchString(this.blamePath, page);
    },
  },
};
</script>
<template>
  <div class="gl-display-flex">
    <div
      class="gl-p-0! gl-absolute gl-z-3 diff-line-num gl-border-r gl-display-flex line-links line-numbers"
    >
      <a
        class="gl-select-none !gl-shadow-none file-line-blame -gl-mx-2 gl-flex-grow-1"
        :href="`${blamePath}${pageSearchString}#L${number}`"
      ></a>
      <a
        :id="`L${number}`"
        class="gl-select-none !gl-shadow-none file-line-num"
        :href="`#L${number}`"
        :data-line-number="number"
      >
        {{ number }}
      </a>
    </div>

    <pre
      class="gl-p-0! gl-w-full gl-overflow-visible! gl-border-none! code highlight gl-leading-0"
    ><code><span :id="`LC${number}`" v-safe-html="content" :lang="language" class="line" data-testid="content"></span></code></pre>
  </div>
</template>
