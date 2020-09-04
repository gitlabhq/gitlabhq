<script>
/* eslint-disable vue/no-v-html */
import { GlTooltipDirective, GlLink, GlButton } from '@gitlab/ui';
import { polyfillSticky } from '~/lib/utils/sticky';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { __, sprintf } from '~/locale';
import scrollDown from '../svg/scroll_down.svg';

export default {
  components: {
    GlLink,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  scrollDown,
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
  mounted() {
    polyfillSticky(this.$el);
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
    <div class="truncated-info d-none d-sm-block float-left" data-testid="log-truncated-info">
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

    <div class="controllers float-right">
      <!-- links -->
      <gl-button
        v-if="rawPath"
        v-gl-tooltip.body
        :title="s__('Job|Show complete raw')"
        :href="rawPath"
        class="controllers-buttons"
        data-testid="job-raw-link-controller"
        icon="doc-text"
      />

      <gl-button
        v-if="erasePath"
        v-gl-tooltip.body
        :title="s__('Job|Erase job log')"
        :href="erasePath"
        :data-confirm="__('Are you sure you want to erase this build?')"
        class="controllers-buttons"
        data-testid="job-log-erase-link"
        data-method="post"
        icon="remove"
      />
      <!-- eo links -->

      <!-- scroll buttons -->
      <div v-gl-tooltip :title="s__('Job|Scroll to top')" class="controllers-buttons">
        <gl-button
          :disabled="isScrollTopDisabled"
          class="btn-scroll btn-transparent btn-blank"
          data-testid="job-controller-scroll-top"
          icon="scroll_up"
          @click="handleScrollToTop"
        />
      </div>

      <div v-gl-tooltip :title="s__('Job|Scroll to bottom')" class="controllers-buttons">
        <gl-button
          :disabled="isScrollBottomDisabled"
          class="js-scroll-bottom btn-scroll btn-transparent btn-blank"
          data-testid="job-controller-scroll-bottom"
          icon="scroll_down"
          :class="{ animate: isScrollingDown }"
          @click="handleScrollToBottom"
          v-html="$options.scrollDown"
        />
      </div>
      <!-- eo scroll buttons -->
    </div>
  </div>
</template>
