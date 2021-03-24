<script>
import { GlButton } from '@gitlab/ui';
import { mapActions } from 'vuex';

export default {
  components: {
    GlButton,
  },
  methods: {
    ...mapActions(['setAddColumnFormVisibility']),
  },
};
</script>

<template>
  <div class="gl-ml-3 gl-display-flex gl-align-items-center" data-testid="boards-create-list">
    <gl-button variant="confirm" @click="setAddColumnFormVisibility(true)"
      >{{ __('Create list') }}
    </gl-button>
  </div>
</template>
