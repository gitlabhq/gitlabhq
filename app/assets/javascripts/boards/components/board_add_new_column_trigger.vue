<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import Tracking from '~/tracking';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin()],
  props: {
    isNewListShowing: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    tooltip() {
      return this.isNewListShowing ? __('The list creation wizard is already open') : '';
    },
  },
  methods: {
    handleClick() {
      this.$emit('setAddColumnFormVisibility', true);
      this.track('click_button', { label: 'create_list' });
    },
  },
};
</script>

<template>
  <div
    v-gl-tooltip="tooltip"
    :tabindex="isNewListShowing ? '0' : undefined"
    class="gl-ml-3 gl-display-flex gl-align-items-center"
    data-testid="boards-create-list"
  >
    <gl-button :disabled="isNewListShowing" variant="confirm" @click="handleClick"
      >{{ __('Create list') }}
    </gl-button>
  </div>
</template>
