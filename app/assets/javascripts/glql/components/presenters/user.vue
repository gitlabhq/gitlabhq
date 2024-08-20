<script>
import { GlLink } from '@gitlab/ui';

export default {
  name: 'UserPresenter',
  components: {
    GlLink,
  },
  props: {
    data: {
      required: true,
      type: Object,
    },
  },
  computed: {
    isCurrentUser() {
      return gon.current_username === this.data.username;
    },
    userId() {
      return this.data.id?.split('/').pop();
    },
  },
};
</script>
<template>
  <gl-link
    class="gfm gfm-project_member js-user-link"
    :href="data.webUrl"
    :title="data.name"
    :data-user="userId"
    :class="{ 'current-user': isCurrentUser }"
    >@{{ data.username }}</gl-link
  >
</template>
