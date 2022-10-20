<script>
import { GlAvatar, GlAvatarLink } from '@gitlab/ui';

export default {
  components: {
    GlAvatar,
    GlAvatarLink,
  },
  props: {
    schedule: {
      type: Object,
      required: true,
    },
  },
  computed: {
    owner() {
      return this.schedule.owner;
    },
  },
};
</script>

<template>
  <div>
    <gl-avatar-link :href="owner.webPath" :title="owner.name" class="gl-ml-3">
      <gl-avatar :size="32" :src="owner.avatarUrl" />
    </gl-avatar-link>
  </div>
</template>
