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
  <span class="gl-ml-4">
    <gl-button variant="success" @click="setAddColumnFormVisibility(true)"
      >{{ __('Create list') }}
    </gl-button>
  </span>
</template>
