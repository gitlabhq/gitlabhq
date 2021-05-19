<script>
import { GlTooltipDirective, GlLink, GlButton } from '@gitlab/ui';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { __, s__, sprintf } from '~/locale';

export default {
  i18n: {
    eraseLogButtonLabel: s__('Job|Erase job log'),
    scrollToBottomButtonLabel: s__('Job|Scroll to bottom'),
    scrollToTopButtonLabel: s__('Job|Scroll to top'),
    showRawButtonLabel: s__('Job|Show complete raw'),
  },
  components: {
    GlLink,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    erasePath: {
      type: String,
      required: false,
      default: null,
    },
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
    isTraceSizeVisible: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    jobLogSize() {
      return sprintf(__('Showing last %{size} of log -'), {
        size: numberToHumanSize(this.size),
      });
    },
  },
  methods: {
    handleScrollToTop() {
      this.$emit('scrollJobLogTop');
    },
    handleScrollToBottom() {
      this.$emit('scrollJobLogBottom');
    },
  },
};
</script>
<template>
  <div class="top-bar">
    <!-- truncate information -->
    <div
      class="truncated-info gl-display-none gl-sm-display-block gl-float-left"
      data-testid="log-truncated-info"
    >
      <template v-if="isTraceSizeVisible">
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

    <div class="controllers gl-float-right">
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

      <gl-button
        v-if="erasePath"
        v-gl-tooltip.body
        :title="$options.i18n.eraseLogButtonLabel"
        :aria-label="$options.i18n.eraseLogButtonLabel"
        :href="erasePath"
        :data-confirm="__('Are you sure you want to erase this build?')"
        class="gl-ml-3"
        data-testid="job-log-erase-link"
        data-method="post"
        icon="remove"
      />
      <!-- eo links -->

      <!-- scroll buttons -->
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
