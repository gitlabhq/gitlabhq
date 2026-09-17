<script>
import {
  GlTooltipDirective,
  GlLink,
  GlButtonGroup,
  GlButton,
  GlSearchBoxByClick,
  GlSprintf,
  GlToastMixin,
} from '@gitlab/ui';
import { backOff } from '~/lib/utils/common_utils';
import { scrollToElement } from '~/lib/utils/scroll_utils';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { s__, n__, sprintf } from '~/locale';
import { compactJobLog, getLineText } from '~/ci/job_details/utils';

export default {
  name: 'JobLogTopBar',
  i18n: {
    scrollToBottomButtonLabel: s__('Job|Scroll to bottom'),
    scrollToTopButtonLabel: s__('Job|Scroll to top'),
    scrollToNextFailureButtonLabel: s__('Job|Scroll to next failure'),
    scrollToNextResult: s__('Job|Scroll to next result'),
    scrollToPreviousResult: s__('Job|Scroll to previous result'),
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
    GlButtonGroup,
    GlButton,
    GlSearchBoxByClick,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [GlToastMixin],
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
  emits: [
    'scroll-job-log-top',
    'scroll-job-log-bottom',
    'search-results',
    'enter-fullscreen',
    'exit-fullscreen',
  ],
  data() {
    return {
      searchTerm: '',
      searchResults: [],
      failureCount: null,
      failureIndex: 0,
      focusedSearchResultIndex: 0,
    };
  },
  computed: {
    canGoToPreviousResult() {
      return Boolean(this.searchResults[this.focusedSearchResultIndex - 1]);
    },
    canGoToNextResult() {
      return Boolean(this.searchResults[this.focusedSearchResultIndex + 1]);
    },
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
    fullScreenButtonLabel() {
      return this.fullScreenEnabled
        ? this.$options.i18n.exitFullScreen
        : this.$options.i18n.enterFullscreen;
    },
    fullScreenTooltipContent() {
      return this.fullScreenModeAvailable
        ? this.fullScreenButtonLabel
        : this.$options.i18n.fullScreenNotAvailable;
    },
  },
  mounted() {
    this.checkFailureCount();
  },
  methods: {
    handleClearSearch() {
      this.$emit('search-results', []);
      this.searchResults = [];
    },
    async scrollToSearchResult(direction) {
      if (direction === 'next') {
        this.focusedSearchResultIndex += 1;
      } else {
        this.focusedSearchResultIndex -= 1;
      }

      const result = this.searchResults[this.focusedSearchResultIndex];
      if (!result) {
        return;
      }

      const targetLogLine = document.querySelector(`.js-log-line #L${result.lineNumber}`);
      if (!targetLogLine) {
        return;
      }

      const topBarHeight = this.$el.offsetHeight || 0;
      await this.$nextTick();
      scrollToElement(targetLogLine, { offset: topBarHeight * -1 });
    },
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
      this.$emit('scroll-job-log-top');
      this.failureIndex = 0;
    },
    handleScrollToBottom() {
      this.$emit('scroll-job-log-bottom');
      this.failureIndex = 0;
    },
    handleToggleFullscreenMode() {
      this.$emit(this.fullScreenEnabled ? 'exit-fullscreen' : 'enter-fullscreen');
    },
    async searchJobLog() {
      this.searchResults = [];

      if (!this.searchTerm) return;

      const compactedLog = compactJobLog(this.jobLog);

      compactedLog.forEach((line) => {
        const lineText = getLineText(line);

        if (lineText.toLocaleLowerCase().includes(this.searchTerm.toLocaleLowerCase())) {
          this.searchResults.push(line);
        }
      });

      if (this.searchResults.length > 0) {
        this.$emit('search-results', this.searchResults);

        const { lineNumber } = this.searchResults[0];
        const targetLogLine = document.querySelector(`.js-log-line #L${lineNumber}`);

        if (targetLogLine) {
          this.focusedSearchResultIndex = 0;

          const topBarHeight = this.$el.offsetHeight || 0;
          await this.$nextTick();
          scrollToElement(targetLogLine, { offset: topBarHeight * -1 });

          const message = sprintf(
            n__(
              'Job|%{searchLength} result found for %{searchTerm}',
              'Job|%{searchLength} results found for %{searchTerm}',
              this.searchResults.length,
            ),
            {
              searchLength: this.searchResults.length,
              searchTerm: this.searchTerm,
            },
          );

          this.$toast.show(message);
        } else {
          this.$toast.show(this.$options.i18n.logLineNumberNotFound);
        }
      } else {
        this.$toast.show(this.$options.i18n.noResults);
      }
    },
  },
  jobLogTestId: { 'data-testid': 'job-log-search-box' },
};
</script>

<template>
  <div
    class="top-bar js-job-log-top-bar gl-flex gl-flex-wrap gl-items-center gl-justify-between gl-gap-3"
  >
    <div class="gl-hidden gl-truncate @sm/panel:gl-block">
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
        :wrapper-attributes="$options.jobLogTestId"
        @clear="handleClearSearch"
        @submit="searchJobLog"
      />

      <div class="gl-flex gl-gap-2">
        <!-- links -->
        <gl-button-group>
          <gl-button
            v-gl-tooltip
            :title="$options.i18n.scrollToPreviousResult"
            :aria-label="$options.i18n.scrollToPreviousResult"
            :disabled="!canGoToPreviousResult"
            data-testid="job-scroll-to-prev-btn"
            icon="chevron-up"
            @click="scrollToSearchResult('prev')"
          />
          <gl-button
            v-gl-tooltip
            :title="$options.i18n.scrollToNextResult"
            :aria-label="$options.i18n.scrollToNextResult"
            :disabled="!canGoToNextResult"
            data-testid="job-scroll-to-next-btn"
            icon="chevron-down"
            @click="scrollToSearchResult('next')"
          />
        </gl-button-group>

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
        <gl-button-group>
          <gl-button
            v-gl-tooltip
            :title="$options.i18n.scrollToNextFailureButtonLabel"
            :aria-label="$options.i18n.scrollToNextFailureButtonLabel"
            :disabled="shouldDisableJumpToFailures"
            data-testid="job-top-bar-scroll-to-failure"
            icon="soft-wrap"
            @click="handleScrollToNextFailure"
          />
          <gl-button
            v-gl-tooltip
            :title="$options.i18n.scrollToTopButtonLabel"
            :disabled="isScrollTopDisabled"
            data-testid="job-top-bar-scroll-top"
            icon="scroll_up"
            :aria-label="$options.i18n.scrollToTopButtonLabel"
            @click="handleScrollToTop"
          />
          <gl-button
            v-gl-tooltip
            :title="$options.i18n.scrollToBottomButtonLabel"
            :disabled="isScrollBottomDisabled"
            data-testid="job-top-bar-scroll-bottom"
            icon="scroll_down"
            :aria-label="$options.i18n.scrollToBottomButtonLabel"
            @click="handleScrollToBottom"
          />
        </gl-button-group>
        <!-- eo scroll buttons -->

        <gl-button
          v-gl-tooltip
          category="tertiary"
          :title="fullScreenTooltipContent"
          :aria-label="fullScreenButtonLabel"
          :disabled="!fullScreenModeAvailable"
          :icon="fullScreenEnabled ? 'minimize' : 'maximize'"
          data-testid="job-top-bar-toggle-fullscreen"
          @click="handleToggleFullscreenMode"
        />
      </div>
    </div>
  </div>
</template>
