<script>
import { GlTooltip, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'BoardExtraActions',
  components: {
    GlTooltip,
    GlButton,
  },
  props: {
    canAdminList: {
      type: Boolean,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: true,
    },
    openModal: {
      type: Function,
      required: true,
    },
  },
  computed: {
    tooltipTitle() {
      if (this.disabled) {
        return __('Please add a list to your board first');
      }

      return '';
    },
  },
};
</script>

<template>
  <div class="board-extra-actions">
    <span ref="addIssuesButtonTooltip" class="gl-ml-3">
      <gl-button
        v-if="canAdminList"
        type="button"
        data-placement="bottom"
        data-track-event="click_button"
        data-track-label="board_add_issues"
        :disabled="disabled"
        :aria-disabled="disabled"
        @click="openModal"
      >
        {{ __('Add issues') }}
      </gl-button>
    </span>
    <gl-tooltip v-if="disabled" :target="() => $refs.addIssuesButtonTooltip" placement="bottom">
      {{ tooltipTitle }}
    </gl-tooltip>
  </div>
</template>
