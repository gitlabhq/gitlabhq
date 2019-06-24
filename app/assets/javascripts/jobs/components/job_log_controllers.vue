<script>
import { GlTooltipDirective, GlLink, GlButton } from '@gitlab/ui';
import { polyfillSticky } from '~/lib/utils/sticky';
import Icon from '~/vue_shared/components/icon.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { __, sprintf } from '~/locale';
import scrollDown from '../svg/scroll_down.svg';

export default {
  components: {
    Icon,
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
    <div class="js-truncated-info truncated-info d-none d-sm-block float-left">
      <template v-if="isTraceSizeVisible">
        {{ jobLogSize }}
        <gl-link
          v-if="rawPath"
          :href="rawPath"
          class="js-raw-link text-plain text-underline prepend-left-5"
          >{{ s__('Job|Complete Raw') }}</gl-link
        >
      </template>
    </div>
    <!-- eo truncate information -->

    <div class="controllers float-right">
      <!-- links -->
      <gl-link
        v-if="rawPath"
        v-gl-tooltip.body
        :title="s__('Job|Show complete raw')"
        :href="rawPath"
        class="js-raw-link-controller controllers-buttons"
      >
        <icon name="doc-text" />
      </gl-link>

      <gl-link
        v-if="erasePath"
        v-gl-tooltip.body
        :title="s__('Job|Erase job log')"
        :href="erasePath"
        :data-confirm="__('Are you sure you want to erase this build?')"
        class="js-erase-link controllers-buttons"
        data-method="post"
      >
        <icon name="remove" />
      </gl-link>
      <!-- eo links -->

      <!-- scroll buttons -->
      <div v-gl-tooltip :title="s__('Job|Scroll to top')" class="controllers-buttons">
        <gl-button
          :disabled="isScrollTopDisabled"
          type="button"
          class="js-scroll-top btn-scroll btn-transparent btn-blank"
          @click="handleScrollToTop"
        >
          <icon name="scroll_up" />
        </gl-button>
      </div>

      <div v-gl-tooltip :title="s__('Job|Scroll to bottom')" class="controllers-buttons">
        <gl-button
          :disabled="isScrollBottomDisabled"
          class="js-scroll-bottom btn-scroll btn-transparent btn-blank"
          :class="{ animate: isScrollingDown }"
          @click="handleScrollToBottom"
          v-html="$options.scrollDown"
        />
      </div>
      <!-- eo scroll buttons -->
    </div>
  </div>
</template>
