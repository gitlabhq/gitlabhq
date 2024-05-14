<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import Tracking from '~/tracking';
import BoardAddNewColumnTriggerPopover from '~/boards/components/board_add_new_column_trigger_popover.vue';

export default {
  components: {
    GlButton,
    GlIcon,
    BoardAddNewColumnTriggerPopover,
  },
  mixins: [Tracking.mixin()],
  props: {
    isNewListShowing: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    scrollToButton(popover) {
      if (popover) {
        this.$el.scrollIntoView({ behavior: 'smooth', inline: 'center' });
      }
    },
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
    <!-- TEMPORARY callout for new "New list" button location -->
    <board-add-new-column-trigger-popover
      @boardAddNewColumnTriggerPopoverRendered="scrollToButton"
    />
  </span>
</template>
