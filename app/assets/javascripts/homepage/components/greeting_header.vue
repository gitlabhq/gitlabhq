<script>
import { __, sprintf } from '~/locale';

export default {
  i18n: {
    welcome: __('Welcome %{name},'),
  },
  computed: {
    userFirstName() {
      return gon.current_user_fullname?.trim().split(' ')[0] || null;
    },
    welcomeMessage() {
      return sprintf(this.$options.i18n.welcome, { name: this.userFirstName });
    },
  },
};
</script>

<template>
  <header class="gl-my-6">
    <p v-if="userFirstName" class="gl-heading-4 gl-mb-2">{{ welcomeMessage }}</p>
    <h1 class="gl-heading-1 gl-m-0">{{ __("Today's highlights") }}</h1>
  </header>
</template>
