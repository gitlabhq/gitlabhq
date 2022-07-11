<script>
import { GlLink, GlSafeHtmlDirective, GlTooltipDirective } from '@gitlab/ui';
import { setAttributes } from '~/lib/utils/dom_utils';
import { BIDI_CHARS, BIDI_CHARS_CLASS_LIST, BIDI_CHAR_TOOLTIP } from '../constants';

export default {
  components: {
    GlLink,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
    GlTooltip: GlTooltipDirective,
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
  <div class="gl-display-flex line-links-wrapper">
    <div
      class="gl-p-0! gl-absolute gl-z-index-3 diff-line-num gl-border-r gl-display-flex line-links line-numbers"
      :class="firstLineClass"
    >
      <gl-link
        v-gl-tooltip="__('View blame')"
        class="gl-user-select-none gl-ml-3 gl-shadow-none! file-line-blame"
        :href="`${blamePath}#L${number}`"
        data-track-action="click_link"
        data-track-label="file_line_action"
        data-track-property="blame"
      />

      <gl-link
        :id="`L${number}`"
        class="gl-user-select-none gl-flex-grow-1 gl-justify-content-end gl-pr-3 gl-shadow-none! file-line-num"
        :to="`#L${number}`"
        :data-line-number="number"
        data-track-action="click_link"
        data-track-label="file_line_action"
        data-track-property="link"
      >
        {{ number }}
      </gl-link>
    </div>

    <pre
      class="gl-p-0! gl-w-full gl-overflow-visible! gl-border-none! code highlight gl-line-height-normal"
      :class="firstLineClass"
    ><code><span :id="`LC${number}`" v-safe-html="formattedContent" :lang="language" class="line" data-testid="content"></span></code></pre>
  </div>
</template>
