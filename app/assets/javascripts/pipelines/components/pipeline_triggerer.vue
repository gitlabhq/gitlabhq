<script>
import userAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import tooltip from '../../vue_shared/directives/tooltip';

export default {
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
  },
  components: {
    userAvatarLink,
  },
  directives: {
    tooltip,
  },
  computed: {
    user() {
      return this.pipeline.user;
    },
  },
};
</script>
<template>
  <div class="table-section section-5 hidden-xs hidden-sm">
    <user-avatar-link
      v-if="user"
      class="js-pipeline-url-user"
      :link-href="pipeline.user.path"
      :img-src="pipeline.user.avatar_url"
      :imgSize=32
      :tooltip-text="pipeline.user.name"
    />
    <span
      v-if="!user"
      class="js-pipeline-url-api api">
      API
    </span>
  </div>
</template>
