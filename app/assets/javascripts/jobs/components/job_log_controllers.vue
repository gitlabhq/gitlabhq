<script>
  import Icon from '~/vue_shared/components/icon.vue';
  import tooltip from '~/vue_shared/directives/tooltip';
  import { numberToHumanSize } from '~/lib/utils/number_utils';
  import { sprintf } from '~/locale';

  export default {
    components: {
      Icon,
    },
    directives: {
      tooltip,
    },
    props: {
      eraseJobPath: {
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
      canScrollToTop: {
        type: Boolean,
        required: true,
      },
      canScrollToBottom: {
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
        return sprintf('Showing last %{startSpanTag} %{size} %{endSpanTag} of log -', {
          startSpanTag: '<span class="s-truncated-info-size truncated-info-size">',
          endSpanTag: '</span>',
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
    <div class="js-truncated-info truncated-info d-none d-sm-block float-left">
      <p
        v-if="isTraceSizeVisible"
        v-html="jobLogSize"
      ></p>

      <a
        v-if="rawPath"
        :href="rawPath"
        class="js-raw-link raw-link"
      >
        {{ s__("Job|Complete Raw") }}
      </a>
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
        v-tooltip
        v-if="eraseJobPath"
        :title="s__('Job|Erase job log')"
        :href="eraseJobPath"
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
          :disabled="!canScrollToTop"
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
          :disabled="!canScrollToBottom"
          type="button"
          class="js-scroll-bottom btn-scroll btn-transparent btn-blank"
          @click="handleScrollToBottom"
        >
          <icon name="scroll_down"/>
        </button>
      </div>
      <!-- eo scroll buttons -->
    </div>
  </div>
</template>
