<script>
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    UserAvatarLink,
  },
  mixins: [glFeatureFlagMixin()],
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
    classes() {
      const triggererClass = 'pipeline-triggerer';

      if (this.glFeatures.newPipelinesTable) {
        return triggererClass;
      }
      return `table-section section-10 d-none d-md-block ${triggererClass}`;
    },
  },
};
</script>
<template>
  <div :class="classes" data-testid="pipeline-triggerer">
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
