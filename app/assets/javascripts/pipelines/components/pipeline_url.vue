<script>
import userAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import tooltipMixin from '../../vue_shared/mixins/tooltip';

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
  mixins: [
    tooltipMixin,
  ],
  computed: {
    user() {
      return this.pipeline.user;
    },
  },
};
</script>
<template>
  <td>
    <a
      :href="pipeline.path"
      class="js-pipeline-url-link">
      <span class="pipeline-id">#{{pipeline.id}}</span>
    </a>
    <span>by</span>
    <user-avatar-link
      v-if="user"
      class="js-pipeline-url-user"
      :link-href="pipeline.user.web_url"
      :img-src="pipeline.user.avatar_url"
      :tooltip-text="pipeline.user.name"
    />
    <span
      v-if="!user"
      class="js-pipeline-url-api api">
      API
    </span>
    <span
      v-if="pipeline.flags.latest"
      class="js-pipeline-url-lastest label label-success"
      title="Latest pipeline for this branch"
      ref="tooltip">
      latest
    </span>
    <span
      v-if="pipeline.flags.yaml_errors"
      class="js-pipeline-url-yaml label label-danger"
      :title="pipeline.yaml_errors"
      ref="tooltip">
      yaml invalid
    </span>
    <span
      v-if="pipeline.flags.stuck"
      class="js-pipeline-url-stuck label label-warning">
      stuck
    </span>
  </td>
</template>
