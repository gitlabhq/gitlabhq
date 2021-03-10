<script>
import { GlTooltipDirective, GlLink, GlButton } from '@gitlab/ui';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { __, sprintf } from '~/locale';

export default {
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
        data-testid="job-raw-link-controller"
        icon="doc-text"
      />

      <gl-button
        v-if="erasePath"
        v-gl-tooltip.body
        :title="s__('Job|Erase job log')"
        :href="erasePath"
        :data-confirm="__('Are you sure you want to erase this build?')"
        class="gl-ml-3"
        data-testid="job-log-erase-link"
        data-method="post"
        icon="remove"
      />
      <!-- eo links -->

      <!-- scroll buttons -->
      <div v-gl-tooltip :title="s__('Job|Scroll to top')" class="gl-ml-3">
        <gl-button
          :disabled="isScrollTopDisabled"
          class="btn-scroll"
          data-testid="job-controller-scroll-top"
          icon="scroll_up"
          @click="handleScrollToTop"
        />
      </div>

      <div v-gl-tooltip :title="s__('Job|Scroll to bottom')" class="gl-ml-3">
        <gl-button
          :disabled="isScrollBottomDisabled"
          class="js-scroll-bottom btn-scroll"
          data-testid="job-controller-scroll-bottom"
          icon="scroll_down"
          :class="{ animate: isScrollingDown }"
          @click="handleScrollToBottom"
        />
      </div>
      <!-- eo scroll buttons -->
    </div>
  </div>
</template>
