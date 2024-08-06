<script>
import { GlTooltipDirective, GlIcon, GlLink } from '@gitlab/ui';
import GlSafeHtmlDirective from '~/vue_shared/directives/safe_html';

export default {
  name: 'BlobChunks',
  components: {
    GlIcon,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml: GlSafeHtmlDirective,
  },
  props: {
    chunk: {
      type: Object,
      required: true,
    },
    blameLink: {
      type: String,
      required: false,
      default: '',
    },
    fileUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    codeTheme() {
      return gon.user_color_scheme || 'white';
    },
  },
  methods: {
    highlightedRichText(richText) {
      return richText.replace('<b>', '<b class="hll">');
    },
  },
};
</script>

<template>
  <div id="search-blob-content" class="file-content code" :class="codeTheme">
    <div class="blob-content" data-blob-id="" data-path="" data-highlight-line="">
      <div
        v-for="line in chunk.lines"
        :key="line.lineNumber"
        class="line_holder code-search-line gl-display-flex"
        data-testid="search-blob-line"
      >
        <div class="line-numbers" data-testid="search-blob-line-numbers">
          <div class="gl-display-flex">
            <span class="diff-line-num gl-pl-3">
              <gl-link
                v-gl-tooltip
                :href="`${blameLink}#L${line.lineNumber}`"
                :title="__('View blame')"
                class="js-navigation-open"
                ><gl-icon name="git"
              /></gl-link>
            </span>
            <span class="diff-line-num flex-grow-1 gl-pr-3">
              <gl-link
                v-gl-tooltip
                :href="`${fileUrl}#L${line.lineNumber}`"
                :title="__('View Line in repository')"
                class="gl-display-flex! gl-align-items-center gl-justify-content-end"
                >{{ line.lineNumber }}</gl-link
              >
            </span>
          </div>
        </div>
        <pre class="code highlight flex-grow-1" data-testid="search-blob-line-code">
          <span v-safe-html="highlightedRichText(line.richText)"></span>
        </pre>
      </div>
    </div>
  </div>
</template>
