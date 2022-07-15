<script>
import { GlLink, GlSafeHtmlDirective } from '@gitlab/ui';
import { setAttributes } from '~/lib/utils/dom_utils';
import { BIDI_CHARS, BIDI_CHARS_CLASS_LIST, BIDI_CHAR_TOOLTIP } from '../constants';

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
    firstLineClass() {
      return { 'gl-mt-3!': this.number === 1 };
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
    <div class="gl-p-0! gl-absolute gl-z-index-3 gl-border-r diff-line-num line-numbers">
      <gl-link
        :id="`L${number}`"
        class="gl-user-select-none gl-ml-5 gl-pr-3 gl-shadow-none! file-line-num diff-line-num"
        :class="firstLineClass"
        :to="`#L${number}`"
        :data-line-number="number"
      >
        {{ number }}
      </gl-link>
    </div>

    <pre
      class="gl-p-0! gl-w-full gl-overflow-visible! gl-ml-11! gl-border-none! code highlight gl-line-height-normal"
      :class="firstLineClass"
    ><code><span :id="`LC${number}`" v-safe-html="formattedContent" :lang="language" class="line" data-testid="content"></span></code></pre>
  </div>
</template>
