<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';

export default {
  i18n: {
    attentionRequiredReviewer: __('Request attention to review'),
    attentionRequiredAssignee: __('Request attention'),
    removeAttentionRequired: __('Remove attention request'),
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
      if (this.user.attention_required) {
        return this.$options.i18n.removeAttentionRequired;
      }

      return this.type === 'reviewer'
        ? this.$options.i18n.attentionRequiredReviewer
        : this.$options.i18n.attentionRequiredAssignee;
    },
  },
  methods: {
    toggleAttentionRequired() {
      if (this.loading) return;

      this.$root.$emit(BV_HIDE_TOOLTIP);
      this.loading = true;
      this.$emit('toggle-attention-required', {
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
      :variant="user.attention_required ? 'warning' : 'default'"
      :icon="user.attention_required ? 'star' : 'star-o'"
      :aria-label="tooltipTitle"
      size="small"
      category="tertiary"
      @click="toggleAttentionRequired"
    />
  </span>
</template>
