<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import Tracking from '~/tracking';

export default {
  name: 'BoardAddNewColumnTrigger',
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
  emits: ['set-add-column-form-visibility'],
  methods: {
    handleClick() {
      this.$emit('set-add-column-form-visibility', true);
      this.track('click_button', { label: 'create_list' });
    },
  },
};
</script>

<template>
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
</template>
