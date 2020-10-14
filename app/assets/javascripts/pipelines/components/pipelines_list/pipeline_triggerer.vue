<script>
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';

export default {
  components: {
    UserAvatarLink,
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
  },
};
</script>
<template>
  <div class="table-section section-10 d-none d-md-block pipeline-triggerer">
    <user-avatar-link
      v-if="user"
      :link-href="user.path"
      :img-src="user.avatar_url"
      :img-size="26"
      :tooltip-text="user.name"
      class="gl-ml-3 js-pipeline-url-user"
    />
    <span v-else class="gl-ml-3 js-pipeline-url-api api">
      {{ s__('Pipelines|API') }}
    </span>
  </div>
</template>
