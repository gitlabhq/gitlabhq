<script>
import { mapActions } from 'vuex';
import { GlButton } from '@gitlab/ui';

export default {
  components: {
    GlButton,
  },
  methods: {
    ...mapActions(['openDrawer']),
  },
};
</script>

<template>
  <li>
    <gl-button variant="link" @click="openDrawer">{{ __("See what's new at GitLab") }}</gl-button>
  </li>
</template>
