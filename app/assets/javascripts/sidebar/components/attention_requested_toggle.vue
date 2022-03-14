<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';

export default {
  i18n: {
    attentionRequestedReviewer: __('Request attention to review'),
    attentionRequestedAssignee: __('Request attention'),
    removeAttentionRequested: __('Remove attention request'),
    attentionRequestedNoPermission: __('Attention requested'),
    noAttentionRequestedNoPermission: __('No attention request'),
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
        if (this.user.can_update_merge_request) {
          return this.$options.i18n.removeAttentionRequested;
        }

        return this.$options.i18n.attentionRequestedNoPermission;
      }

      if (this.user.can_update_merge_request) {
        return this.type === 'reviewer'
          ? this.$options.i18n.attentionRequestedReviewer
          : this.$options.i18n.attentionRequestedAssignee;
      }

      return this.$options.i18n.noAttentionRequestedNoPermission;
    },
  },
  methods: {
    toggleAttentionRequired() {
      if (this.loading || !this.user.can_update_merge_request) return;

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
  <span
    v-gl-tooltip.left.viewport="tooltipTitle"
    class="gl-display-inline-block js-attention-request-toggle"
  >
    <gl-button
      :loading="loading"
      :variant="user.attention_requested ? 'warning' : 'default'"
      :icon="user.attention_requested ? 'attention-solid' : 'attention'"
      :aria-label="tooltipTitle"
      :class="{ 'gl-pointer-events-none': !user.can_update_merge_request }"
      size="small"
      category="tertiary"
      @click="toggleAttentionRequired"
    />
  </span>
</template>
