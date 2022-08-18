<script>
import { GlSafeHtmlDirective } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { setAttributes } from '~/lib/utils/dom_utils';
import { BIDI_CHARS, BIDI_CHARS_CLASS_LIST, BIDI_CHAR_TOOLTIP } from '../constants';

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
    formattedContent() {
      let { content } = this;

      BIDI_CHARS.forEach((bidiChar) => {
        if (content.includes(bidiChar)) {
          content = content.replace(bidiChar, this.wrapBidiChar(bidiChar));
        }
      });

      return content;
    },
  },
  methods: {
    wrapBidiChar(bidiChar) {
      const span = document.createElement('span');

      setAttributes(span, {
        class: BIDI_CHARS_CLASS_LIST,
        title: BIDI_CHAR_TOOLTIP,
        'data-testid': 'bidi-wrapper',
      });

      span.innerText = bidiChar;

      return span.outerHTML;
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
        :href="`${blamePath}#L${number}`"
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
      class="gl-p-0! gl-w-full gl-overflow-visible! gl-border-none! code highlight gl-line-height-normal"
    ><code><span :id="`LC${number}`" v-safe-html="formattedContent" :lang="language" class="line" data-testid="content"></span></code></pre>
  </div>
</template>
