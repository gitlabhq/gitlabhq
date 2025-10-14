<script>
import { GlAvatarLink, GlAvatar, GlTooltipDirective } from '@gitlab/ui';

export default {
  components: {
    GlAvatarLink,
    GlAvatar,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
  },
  computed: {
    user() {
      return this.pipeline.user;
    },
    userPath() {
      return this.user?.path || this.user?.webPath;
    },
    avatarUrl() {
      return this.user?.avatar_url || this.user?.avatarUrl;
    },
  },
};
</script>
<template>
  <div class="pipeline-triggerer" data-testid="pipeline-triggerer">
    <gl-avatar-link v-if="user" v-gl-tooltip :href="userPath" :title="user.name" class="gl-ml-3">
      <gl-avatar :size="32" :src="avatarUrl" />
    </gl-avatar-link>
  </div>
</template>
