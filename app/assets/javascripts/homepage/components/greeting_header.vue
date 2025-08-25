<script>
import { __, sprintf } from '~/locale';

export default {
  i18n: {
    greeting: __('Hi, %{name}'),
  },
  computed: {
    userFirstName() {
      return gon.current_user_fullname?.trim().split(' ')[0] || null;
    },
    relevantName() {
      return this.userFirstName || gon.current_username;
    },
    greeting() {
      return sprintf(this.$options.i18n.greeting, { name: this.relevantName });
    },
    avatar() {
      return gon?.current_user_avatar_url;
    },
  },
};
</script>

<template>
  <div class="gl-mb-7 gl-mt-8 gl-flex gl-flex-row gl-items-center gl-gap-x-5">
    <img
      :src="avatar"
      class="gl-avatar gl-avatar-s64 gl-avatar-circle"
      loading="lazy"
      itemprop="image"
      :alt="`avatar for ${relevantName}`"
    />
    <header>
      <p class="gl-heading-5 gl-mb-2 gl-truncate gl-text-subtle">{{ __("Today's highlights") }}</p>
      <h1 v-if="relevantName" class="gl-heading-display gl-m-0">{{ greeting }}</h1>
    </header>
  </div>
</template>
