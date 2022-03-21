<script>
import { GlLink, GlSafeHtmlDirective } from '@gitlab/ui';

export default {
  components: {
    GlLink,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
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
  },
};
</script>
<template>
  <div class="gl-display-flex">
    <div class="line-numbers gl-pt-0! gl-pb-0! gl-absolute gl-z-index-3">
      <gl-link
        :id="`L${number}`"
        class="file-line-num diff-line-num gl-user-select-none"
        :to="`#L${number}`"
        :data-line-number="number"
      >
        {{ number }}
      </gl-link>
    </div>

    <pre
      class="code highlight gl-p-0! gl-w-full gl-overflow-visible! gl-ml-11!"
    ><code><span :id="`LC${number}`" v-safe-html="content" :lang="language" class="line" data-testid="content"></span></code></pre>
  </div>
</template>
