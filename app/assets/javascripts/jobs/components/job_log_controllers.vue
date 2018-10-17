<script>
import { polyfillSticky } from '~/lib/utils/sticky';
import Icon from '~/vue_shared/components/icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { sprintf } from '~/locale';
import scrollDown from '../svg/scroll_down.svg';

export default {
  components: {
    Icon,
  },
  directives: {
    tooltip,
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
      return sprintf('Showing last %{size} of log -', {
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
  <div class="top-bar affix">
    <!-- truncate information -->
    <div class="js-truncated-info truncated-info d-none d-sm-block float-left">
      <template v-if="isTraceSizeVisible">
        {{ jobLogSize }}

        <a
          v-if="rawPath"
          :href="rawPath"
          class="js-raw-link raw-link"
        >
          {{ s__("Job|Complete Raw") }}
        </a>
      </template>
    </div>
    <!-- eo truncate information -->

    <div class="controllers float-right">
      <!-- links -->
      <a
        v-if="rawPath"
        v-tooltip
        :title="s__('Job|Show complete raw')"
        :href="rawPath"
        class="js-raw-link-controller controllers-buttons"
        data-container="body"
      >
        <icon name="doc-text" />
      </a>

      <a
        v-if="erasePath"
        v-tooltip
        :title="s__('Job|Erase job log')"
        :href="erasePath"
        :data-confirm="__('Are you sure you want to erase this build?')"
        class="js-erase-link controllers-buttons"
        data-container="body"
        data-method="post"
      >
        <icon name="remove" />
      </a>
      <!-- eo links -->

      <!-- scroll buttons -->
      <div
        v-tooltip
        :title="s__('Job|Scroll to top')"
        class="controllers-buttons"
        data-container="body"
      >
        <button
          :disabled="isScrollTopDisabled"
          type="button"
          class="js-scroll-top btn-scroll btn-transparent btn-blank"
          @click="handleScrollToTop"
        >
          <icon name="scroll_up"/>
        </button>
      </div>

      <div
        v-tooltip
        :title="s__('Job|Scroll to bottom')"
        class="controllers-buttons"
        data-container="body"
      >
        <button
          :disabled="isScrollBottomDisabled"
          type="button"
          class="js-scroll-bottom btn-scroll btn-transparent btn-blank"
          :class="{ animate: isScrollingDown }"
          @click="handleScrollToBottom"
          v-html="$options.scrollDown"
        >
        </button>
      </div>
      <!-- eo scroll buttons -->
    </div>
  </div>
</template>
