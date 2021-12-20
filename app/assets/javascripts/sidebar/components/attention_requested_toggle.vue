<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';

export default {
  i18n: {
    attentionRequestedReviewer: __('Request attention to review'),
    attentionRequestedAssignee: __('Request attention'),
    removeAttentionRequested: __('Remove attention request'),
  },
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    type: {
      type: String,
      required: true,
    },
    user: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      loading: false,
    };
  },
  computed: {
    tooltipTitle() {
      if (this.user.attention_requested) {
        return this.$options.i18n.removeAttentionRequested;
      }

      return this.type === 'reviewer'
        ? this.$options.i18n.attentionRequestedReviewer
        : this.$options.i18n.attentionRequestedAssignee;
    },
  },
  methods: {
    toggleAttentionRequired() {
      if (this.loading) return;

      this.$root.$emit(BV_HIDE_TOOLTIP);
      this.loading = true;
      this.$emit('toggle-attention-requested', {
        user: this.user,
        callback: this.toggleAttentionRequiredComplete,
      });
    },
    toggleAttentionRequiredComplete() {
      this.loading = false;
    },
  },
};
</script>

<template>
  <span v-gl-tooltip.left.viewport="tooltipTitle">
    <gl-button
      :loading="loading"
      :variant="user.attention_requested ? 'warning' : 'default'"
      :icon="user.attention_requested ? 'attention-solid' : 'attention'"
      :aria-label="tooltipTitle"
      size="small"
      category="tertiary"
      @click="toggleAttentionRequired"
    />
  </span>
</template>
