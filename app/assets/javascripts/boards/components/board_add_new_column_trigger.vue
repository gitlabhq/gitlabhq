<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import Tracking from '~/tracking';

export default {
  components: {
    GlButton,
    GlIcon,
  },
  mixins: [Tracking.mixin()],
  props: {
    isNewListShowing: {
      type: Boolean,
      required: true,
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
  <span>
    <gl-button
      v-show="!isNewListShowing"
      id="boards-create-list"
      data-testid="boards-create-list"
      variant="default"
      @click="handleClick"
    >
      <gl-icon name="plus" :size="16" />
      {{ __('New list') }}
    </gl-button>
  </span>
</template>
