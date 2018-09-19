<script>
  import Icon from '~/vue_shared/components/icon.vue';
  import tooltip from '~/vue_shared/directives/tooltip';
  import { numberToHumanSize } from '~/lib/utils/number_utils';
  import { s__, sprintf } from '~/locale';

  export default {
    components: {
      Icon,
    },
    directives: {
      tooltip,
    },
    props: {
      canEraseJob: {
        type: Boolean,
        required: true,
      },
      size: {
        type: Number,
        required: true,
      },
      rawTracePath: {
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
      handleEraseJobClick() {
        // eslint-disable-next-line no-alert
        if (window.confirm(s__('Job|Are you sure you want to erase this job?'))) {
          this.$emit('eraseJob');
        }
      },
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
      <p v-html="jobLogSize"></p>

      <a
        v-if="rawTracePath"
        :href="rawTracePath"
        class="js-raw-link raw-link"
      >
        {{ s__("Job|Complete Raw") }}
      </a>
    </div>
    <!-- eo truncate information -->

    <div class="controllers float-right">
      <!-- links -->
      <a
        v-tooltip
        v-if="rawTracePath"
        :title="s__('Job|Show complete raw')"
        :href="rawTracePath"
        class="js-raw-link-controller controllers-buttons"
        data-container="body"
      >
        <icon name="doc-text" />
      </a>

      <button
        v-tooltip
        v-if="canEraseJob"
        :title="s__('Job|Erase job log')"
        type="button"
        class="js-erase-link controllers-buttons"
        data-container="body"
        @click="handleEraseJobClick"
      >
        <icon name="remove" />
      </button>
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
