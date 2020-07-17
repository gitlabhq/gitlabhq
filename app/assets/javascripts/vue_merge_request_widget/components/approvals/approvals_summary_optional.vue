<script>
import { GlTooltipDirective, GlLink } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import {
  OPTIONAL,
  OPTIONAL_CAN_APPROVE,
} from '~/vue_merge_request_widget/components/approvals/messages';

export default {
  components: {
    GlLink,
    Icon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    canApprove: {
      type: Boolean,
      required: true,
    },
    helpPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    message() {
      return this.canApprove ? OPTIONAL_CAN_APPROVE : OPTIONAL;
    },
  },
};
</script>

<template>
  <div class="d-flex align-items-center">
    <span class="text-muted">{{ message }}</span>
    <gl-link
      v-if="canApprove && helpPath"
      v-gl-tooltip
      :href="helpPath"
      :title="__('About this feature')"
      target="_blank"
      class="d-flex-center pl-1"
    >
      <icon name="question" />
    </gl-link>
  </div>
</template>
