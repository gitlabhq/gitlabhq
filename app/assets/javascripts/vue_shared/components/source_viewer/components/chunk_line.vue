<script>
import { GlSafeHtmlDirective } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { getPageParamValue, getPageSearchString } from '~/blob/utils';

export default {
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  mixins: [glFeatureFlagMixin()],
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
      if (!this.glFeatures.fileLineBlame) return '';
      const page = getPageParamValue(this.number);
      return getPageSearchString(this.blamePath, page);
    },
  },
};
</script>
<template>
  <div class="gl-display-flex">
    <div
      class="gl-p-0! gl-absolute gl-z-index-3 diff-line-num gl-border-r gl-display-flex line-links line-numbers"
    >
      <a
        v-if="glFeatures.fileLineBlame"
        class="gl-user-select-none gl-shadow-none! file-line-blame"
        :href="`${blamePath}${pageSearchString}#L${number}`"
      ></a>
      <a
        :id="`L${number}`"
        class="gl-user-select-none gl-shadow-none! file-line-num"
        :href="`#L${number}`"
        :data-line-number="number"
      >
        {{ number }}
      </a>
    </div>

    <pre
      class="gl-p-0! gl-w-full gl-overflow-visible! gl-border-none! code highlight gl-line-height-0"
    ><code><span :id="`LC${number}`" v-safe-html="content" :lang="language" class="line" data-testid="content"></span></code></pre>
  </div>
</template>
