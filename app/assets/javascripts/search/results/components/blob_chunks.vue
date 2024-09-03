<script>
import { GlTooltipDirective, GlIcon, GlLink } from '@gitlab/ui';
import GlSafeHtmlDirective from '~/vue_shared/directives/safe_html';
import { s__ } from '~/locale';
import { InternalEvents } from '~/tracking';
import {
  EVENT_CLICK_BLOB_RESULT_LINE,
  EVENT_CLICK_BLOB_RESULT_BLAME_LINE,
} from '~/search/results/tracking';

const trackingMixin = InternalEvents.mixin();

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
  mixins: [trackingMixin],
  i18n: {
    viewBlame: s__('GlobalSearch|View blame'),
    viewLine: s__('GlobalSearch|View line in repository'),
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
    position: {
      type: Number,
      required: true,
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
    trackLineClick(lineNumber) {
      this.trackEvent(EVENT_CLICK_BLOB_RESULT_LINE, {
        property: lineNumber,
        value: this.position,
      });
    },
    trackBlameClick(lineNumber) {
      this.trackEvent(EVENT_CLICK_BLOB_RESULT_BLAME_LINE, {
        property: lineNumber,
        value: this.position,
      });
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
        class="line_holder code-search-line gl-flex"
        data-testid="search-blob-line"
      >
        <div class="line-numbers" data-testid="search-blob-line-numbers">
          <div class="gl-flex">
            <span class="diff-line-num gl-pl-3">
              <gl-link
                v-gl-tooltip
                :href="`${blameLink}#L${line.lineNumber}`"
                :title="$options.i18n.viewBlame"
                class="js-navigation-open"
                data-testid="search-blob-line-blame-link"
                @click="trackBlameClick(line.lineNumber)"
                ><gl-icon name="git"
              /></gl-link>
            </span>
            <span class="diff-line-num gl-grow gl-pr-3">
              <gl-link
                v-gl-tooltip
                :href="`${fileUrl}#L${line.lineNumber}`"
                :title="$options.i18n.viewLine"
                class="!gl-flex gl-items-center gl-justify-end"
                data-testid="search-blob-line-link"
                @click="trackLineClick(line.lineNumber)"
                >{{ line.lineNumber }}</gl-link
              >
            </span>
          </div>
        </div>
        <pre class="code highlight gl-grow" data-testid="search-blob-line-code">
          <code class="!gl-inline">
            <span v-safe-html="highlightedRichText(line.richText)" class="line"></span>
          </code>
        </pre>
      </div>
    </div>
  </div>
</template>
