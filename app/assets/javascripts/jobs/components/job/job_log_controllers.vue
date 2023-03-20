<script>
import { GlTooltipDirective, GlLink, GlButton, GlSearchBoxByClick } from '@gitlab/ui';
import { scrollToElement, backOff } from '~/lib/utils/common_utils';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { __, s__, sprintf } from '~/locale';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  i18n: {
    scrollToBottomButtonLabel: s__('Job|Scroll to bottom'),
    scrollToTopButtonLabel: s__('Job|Scroll to top'),
    scrollToNextFailureButtonLabel: s__('Job|Scroll to next failure'),
    showRawButtonLabel: s__('Job|Show complete raw'),
    searchPlaceholder: s__('Job|Search job log'),
    noResults: s__('Job|No search results found'),
    searchPopoverTitle: s__('Job|Job log search'),
    searchPopoverDescription: s__(
      'Job|Search for substrings in your job log output. Currently search is only supported for the visible job log output, not for any log output that is truncated due to size.',
    ),
    logLineNumberNotFound: s__('Job|We could not find this element'),
  },
  components: {
    GlLink,
    GlButton,
    GlSearchBoxByClick,
    HelpPopover,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin()],
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
    jobLogSize() {
      return sprintf(__('Showing last %{size} of log -'), {
        size: numberToHumanSize(this.size),
      });
    },
    showJumpToFailures() {
      return this.glFeatures.jobLogJumpToFailures;
    },
    hasFailures() {
      return this.failureCount > 0;
    },
    shouldDisableJumpToFailures() {
      return !this.hasFailures;
    },
  },
  mounted() {
    this.checkFailureCount();
  },
  methods: {
    checkFailureCount() {
      if (this.glFeatures.jobLogJumpToFailures) {
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
      }
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
    searchJobLog() {
      this.searchResults = [];

      if (!this.searchTerm) return;

      const compactedLog = [];

      this.jobLog.forEach((obj) => {
        if (obj.lines && obj.lines.length > 0) {
          compactedLog.push(...obj.lines);
        }

        if (!obj.lines && obj.content.length > 0) {
          compactedLog.push(obj);
        }
      });

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
        const logLine = document.querySelector(`.js-line ${firstSearchResult}`);

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
  <div class="top-bar gl-display-flex gl-justify-content-space-between">
    <!-- truncate information -->
    <div
      class="truncated-info gl-display-none gl-sm-display-flex gl-flex-wrap gl-align-items-center"
      data-testid="log-truncated-info"
    >
      <template v-if="isJobLogSizeVisible">
        {{ jobLogSize }}
        <gl-link
          v-if="rawPath"
          :href="rawPath"
          class="text-plain text-underline gl-ml-2"
          data-testid="raw-link"
          >{{ s__('Job|Complete Raw') }}</gl-link
        >
      </template>
    </div>
    <!-- eo truncate information -->

    <div class="controllers">
      <gl-search-box-by-click
        v-model="searchTerm"
        class="gl-mr-3"
        :placeholder="$options.i18n.searchPlaceholder"
        data-testid="job-log-search-box"
        @clear="$emit('searchResults', [])"
        @submit="searchJobLog"
      />

      <help-popover class="gl-mr-3">
        <template #title>{{ $options.i18n.searchPopoverTitle }}</template>

        <p class="gl-mb-0">
          {{ $options.i18n.searchPopoverDescription }}
        </p>
      </help-popover>

      <!-- links -->
      <gl-button
        v-if="rawPath"
        v-gl-tooltip.body
        :title="$options.i18n.showRawButtonLabel"
        :aria-label="$options.i18n.showRawButtonLabel"
        :href="rawPath"
        data-testid="job-raw-link-controller"
        icon="doc-text"
      />
      <!-- eo links -->

      <!-- scroll buttons -->
      <gl-button
        v-if="showJumpToFailures"
        v-gl-tooltip
        :title="$options.i18n.scrollToNextFailureButtonLabel"
        :aria-label="$options.i18n.scrollToNextFailureButtonLabel"
        :disabled="shouldDisableJumpToFailures"
        class="btn-scroll gl-ml-3"
        data-testid="job-controller-scroll-to-failure"
        icon="soft-wrap"
        @click="handleScrollToNextFailure"
      />

      <div v-gl-tooltip :title="$options.i18n.scrollToTopButtonLabel" class="gl-ml-3">
        <gl-button
          :disabled="isScrollTopDisabled"
          class="btn-scroll"
          data-testid="job-controller-scroll-top"
          icon="scroll_up"
          :aria-label="$options.i18n.scrollToTopButtonLabel"
          @click="handleScrollToTop"
        />
      </div>

      <div v-gl-tooltip :title="$options.i18n.scrollToBottomButtonLabel" class="gl-ml-3">
        <gl-button
          :disabled="isScrollBottomDisabled"
          class="js-scroll-bottom btn-scroll"
          data-testid="job-controller-scroll-bottom"
          icon="scroll_down"
          :class="{ animate: isScrollingDown }"
          :aria-label="$options.i18n.scrollToBottomButtonLabel"
          @click="handleScrollToBottom"
        />
      </div>
      <!-- eo scroll buttons -->
    </div>
  </div>
</template>
