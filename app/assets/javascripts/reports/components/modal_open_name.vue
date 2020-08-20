<script>
import { GlTooltipDirective, GlResizeObserverDirective } from '@gitlab/ui';
import { mapActions } from 'vuex';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
    GlResizeObserverDirective,
  },
  props: {
    issue: {
      type: Object,
      required: true,
    },
    // failed || success
    status: {
      type: String,
      required: true,
    },
  },
  data: () => ({
    tooltipTitle: '',
  }),
  mounted() {
    this.updateTooltipTitle();
  },
  methods: {
    ...mapActions(['openModal']),
    handleIssueClick() {
      const { issue, status, openModal } = this;
      openModal({ issue, status });
    },
    updateTooltipTitle() {
      // Only show the tooltip if the text is truncated with an ellipsis.
      this.tooltipTitle = this.$el.offsetWidth < this.$el.scrollWidth ? this.issue.title : '';
    },
  },
};
</script>
<template>
  <button
    v-gl-tooltip="{ boundary: 'viewport' }"
    v-gl-resize-observer-directive="updateTooltipTitle"
    class="btn-link gl-text-truncate"
    :aria-label="s__('Reports|Vulnerability Name')"
    :title="tooltipTitle"
    @click="handleIssueClick()"
  >
    {{ issue.title }}
  </button>
</template>
