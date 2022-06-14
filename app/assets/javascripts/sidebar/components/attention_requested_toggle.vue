<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';

export default {
  i18n: {
    addAttentionRequest: __('Add attention request'),
    removeAttentionRequest: __('Remove attention request'),
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
          return this.$options.i18n.removeAttentionRequest;
        }

        return this.$options.i18n.attentionRequestedNoPermission;
      }

      if (this.user.can_update_merge_request) {
        return this.$options.i18n.addAttentionRequest;
      }

      return this.$options.i18n.noAttentionRequestedNoPermission;
    },
    request() {
      const state = {
        selected: false,
        icon: 'attention',
        direction: 'add',
      };

      if (this.user.attention_requested) {
        Object.assign(state, {
          selected: true,
          icon: 'attention-solid',
          direction: 'remove',
        });
      }

      return state;
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
        direction: this.request.direction,
      });
    },
    toggleAttentionRequiredComplete() {
      this.loading = false;
    },
  },
};
</script>

<template>
  <div>
    <span
      v-gl-tooltip.left.viewport="tooltipTitle"
      class="gl-display-inline-block js-attention-request-toggle"
    >
      <gl-button
        :loading="loading"
        :selected="request.selected"
        :icon="request.icon"
        :aria-label="tooltipTitle"
        :class="{ 'gl-pointer-events-none': !user.can_update_merge_request }"
        size="small"
        category="tertiary"
        @click="toggleAttentionRequired"
      />
    </span>
  </div>
</template>
