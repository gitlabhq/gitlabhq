<script>
import { GlButton } from '@gitlab/ui';
import { mapActions } from 'vuex';
import Tracking from '~/tracking';

export default {
  components: {
    GlButton,
  },
  mixins: [Tracking.mixin()],
  methods: {
    ...mapActions(['setAddColumnFormVisibility']),
    handleClick() {
      this.setAddColumnFormVisibility(true);
      this.track('click_button', { label: 'create_list' });
    },
  },
};
</script>

<template>
  <div class="gl-ml-3 gl-display-flex gl-align-items-center" data-testid="boards-create-list">
    <gl-button variant="confirm" @click="handleClick">{{ __('Create list') }} </gl-button>
  </div>
</template>
