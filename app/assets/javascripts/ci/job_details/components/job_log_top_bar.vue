<script>
import { GlTooltipDirective, GlLink, GlButton, GlSearchBoxByClick, GlSprintf } from '@gitlab/ui';
import { scrollToElement, backOff } from '~/lib/utils/common_utils';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { s__, sprintf } from '~/locale';
import { compactJobLog } from '~/ci/job_details/utils';

export default {
  i18n: {
    scrollToBottomButtonLabel: s__('Job|Scroll to bottom'),
    scrollToTopButtonLabel: s__('Job|Scroll to top'),
    scrollToNextFailureButtonLabel: s__('Job|Scroll to next failure'),
    showRawButtonLabel: s__('Job|Show complete raw'),
    searchPlaceholder: s__('Job|Search visible log output'),
    noResults: s__('Job|No search results found'),
    logLineNumberNotFound: s__('Job|We could not find this element'),
    enterFullscreen: s__('Job|Show full screen'),
    exitFullScreen: s__('Job|Exit full screen'),
    fullScreenNotAvailable: s__('Job|Full screen mode is not available'),
  },
  components: {
    GlLink,
    GlButton,
    GlSearchBoxByClick,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    size: {
      type: Number,
      required: true,
    },
    rawPath: {
      type: String,
      required: false,
      default: null,
    },
    isScrollTopDisabled: {
      type: Boolean,
      required: true,
    },
    isScrollBottomDisabled: {
      type: Boolean,
      required: true,
    },
    isScrollingDown: {
      type: Boolean,
      required: true,
    },
    isJobLogSizeVisible: {
      type: Boolean,
      required: true,
    },
    isComplete: {
      type: Boolean,
      required: true,
    },
    jobLog: {
      type: Array,
      required: true,
    },
    fullScreenModeAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    fullScreenEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    logViewerPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      searchTerm: '',
      searchResults: [],
      failureCount: null,
      failureIndex: 0,
    };
  },
  computed: {
    hasTimestamps() {
      return Boolean(this.jobLog[0]?.time);
    },
    jobLogSize() {
      return sprintf(s__('Job|Showing last %{size} of log.'), {
        size: numberToHumanSize(this.size),
      });
    },
    hasFailures() {
      return this.failureCount > 0;
    },
    shouldDisableJumpToFailures() {
      return !this.hasFailures;
    },
    fullScreenTooltipContent() {
      return this.fullScreenModeAvailable ? '' : this.$options.i18n.fullScreenNotAvailable;
    },
  },
  mounted() {
    this.checkFailureCount();
  },
  methods: {
    checkFailureCount() {
      backOff((next, stop) => {
        this.failureCount = document.querySelectorAll('.term-fg-l-red').length;

        if (this.hasFailures || (this.isComplete && !this.hasFailures)) {
          stop();
        } else {
          next();
        }
      }).catch(() => {
        this.failureCount = null;
      });
    },
    handleScrollToNextFailure() {
      const failures = document.querySelectorAll('.term-fg-l-red');
      const nextFailure = failures[this.failureIndex];

      if (nextFailure) {
        nextFailure.scrollIntoView({ block: 'center' });
        this.failureIndex = (this.failureIndex + 1) % failures.length;
      }
    },
    handleScrollToTop() {
      this.$emit('scrollJobLogTop');
      this.failureIndex = 0;
    },
    handleScrollToBottom() {
      this.$emit('scrollJobLogBottom');
      this.failureIndex = 0;
    },
    handleFullscreenMode() {
      this.$emit('enterFullscreen');
    },
    handleExitFullscreenMode() {
      this.$emit('exitFullscreen');
    },
    searchJobLog() {
      this.searchResults = [];

      if (!this.searchTerm) return;

      const compactedLog = compactJobLog(this.jobLog);

      compactedLog.forEach((line) => {
        const lineText = line.content[0].text;

        if (lineText.toLocaleLowerCase().includes(this.searchTerm.toLocaleLowerCase())) {
          this.searchResults.push(line);
        }
      });

      if (this.searchResults.length > 0) {
        this.$emit('searchResults', this.searchResults);

        // BE returns zero based index, we need to add one to match the line numbers in the DOM
        const firstSearchResult = `#L${this.searchResults[0].lineNumber + 1}`;
        const logLine = document.querySelector(`.js-log-line ${firstSearchResult}`);

        if (logLine) {
          setTimeout(() => scrollToElement(logLine));

          const message = sprintf(s__('Job|%{searchLength} results found for %{searchTerm}'), {
            searchLength: this.searchResults.length,
            searchTerm: this.searchTerm,
          });

          this.$toast.show(message);
        } else {
          this.$toast.show(this.$options.i18n.logLineNumberNotFound);
        }
      } else {
        this.$toast.show(this.$options.i18n.noResults);
      }
    },
  },
};
</script>
<template>
  <div class="top-bar gl-flex gl-flex-wrap gl-items-center gl-justify-between gl-gap-3">
    <div class="gl-hidden gl-truncate sm:gl-block">
      <!-- truncated log information -->
      <span data-testid="showing-last">
        <template v-if="isJobLogSizeVisible">
          {{ jobLogSize }}
          <gl-sprintf
            v-if="rawPath && isComplete && logViewerPath"
            :message="
              s__(
                'Job|%{rawLinkStart}View raw%{rawLinkEnd} or %{fullLinkStart}full log%{fullLinkEnd}.',
              )
            "
          >
            <template #rawLink="{ content }">
              <gl-link :href="rawPath">{{ content }}</gl-link>
            </template>
            <template #fullLink="{ content }">
              <gl-link :href="logViewerPath"> {{ content }}</gl-link>
            </template>
          </gl-sprintf>
          <gl-link v-else-if="rawPath" :href="rawPath">{{ s__('Job|View raw') }}</gl-link>
        </template>
      </span>
      <!-- eo truncated log information -->
      <span v-if="hasTimestamps" class="gl-ml-2 gl-text-subtle">
        {{ s__('Job|Log timestamps in UTC.') }}
      </span>
    </div>

    <div class="gl-flex gl-flex-wrap gl-gap-3">
      <slot name="controllers"> </slot>

      <gl-search-box-by-click
        v-model="searchTerm"
        class="gl-w-30 gl-grow gl-flex-nowrap"
        :placeholder="$options.i18n.searchPlaceholder"
        data-testid="job-log-search-box"
        @clear="$emit('searchResults', [])"
        @submit="searchJobLog"
      />

      <div class="gl-flex gl-gap-2">
        <!-- links -->
        <gl-button
          v-if="rawPath"
          v-gl-tooltip.body
          :title="$options.i18n.showRawButtonLabel"
          :aria-label="$options.i18n.showRawButtonLabel"
          :href="rawPath"
          data-testid="job-raw-link-controller"
          icon="doc-code"
        />
        <!-- eo links -->

        <!-- scroll buttons -->
        <gl-button
          v-gl-tooltip
          :title="$options.i18n.scrollToNextFailureButtonLabel"
          :aria-label="$options.i18n.scrollToNextFailureButtonLabel"
          :disabled="shouldDisableJumpToFailures"
          class="btn-scroll"
          data-testid="job-top-bar-scroll-to-failure"
          icon="soft-wrap"
          @click="handleScrollToNextFailure"
        />

        <div v-gl-tooltip :title="$options.i18n.scrollToTopButtonLabel">
          <gl-button
            :disabled="isScrollTopDisabled"
            class="btn-scroll"
            data-testid="job-top-bar-scroll-top"
            icon="scroll_up"
            :aria-label="$options.i18n.scrollToTopButtonLabel"
            @click="handleScrollToTop"
          />
        </div>

        <div v-gl-tooltip :title="$options.i18n.scrollToBottomButtonLabel">
          <gl-button
            :disabled="isScrollBottomDisabled"
            class="js-scroll-bottom btn-scroll"
            data-testid="job-top-bar-scroll-bottom"
            icon="scroll_down"
            :class="{ animate: isScrollingDown }"
            :aria-label="$options.i18n.scrollToBottomButtonLabel"
            @click="handleScrollToBottom"
          />
        </div>
        <!-- eo scroll buttons -->

        <div v-gl-tooltip="fullScreenTooltipContent">
          <gl-button
            v-if="!fullScreenEnabled"
            :disabled="!fullScreenModeAvailable"
            :title="$options.i18n.enterFullscreen"
            :aria-label="$options.i18n.enterFullscreen"
            class="btn-scroll"
            data-testid="job-top-bar-enter-fullscreen"
            icon="maximize"
            @click="handleFullscreenMode"
          />
        </div>

        <gl-button
          v-if="fullScreenEnabled"
          :title="$options.i18n.exitFullScreen"
          :aria-label="$options.i18n.exitFullScreen"
          class="btn-scroll"
          data-testid="job-top-bar-exit-fullscreen"
          icon="minimize"
          @click="handleExitFullscreenMode"
        />
      </div>
    </div>
  </div>
</template>
