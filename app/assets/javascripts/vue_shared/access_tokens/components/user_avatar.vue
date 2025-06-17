<script>
import { GlAvatarLabeled, GlLoadingIcon } from '@gitlab/ui';
import { getUser } from '~/api/user_api';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

export default {
  components: {
    GlAvatarLabeled,
    GlLoadingIcon,
  },
  props: {
    id: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      loading: true,
      avatarUrl: '',
      name: '',
      username: '',
    };
  },
  async created() {
    try {
      const { data } = await getUser(this.id);
      this.avatarUrl = data.avatar_url;
      this.name = data.name;
      this.username = `@${data.username}`;
    } catch (error) {
      Sentry.captureException(error);
    } finally {
      this.loading = false;
    }
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="loading" />
    <gl-avatar-labeled
      v-else-if="name"
      :label="name"
      :sub-label="username"
      :src="avatarUrl"
      :size="32"
      class="gl-mt-5"
      fallback-on-error
    />
  </div>
</template>
