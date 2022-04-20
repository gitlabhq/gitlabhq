<script>
import { GlAvatarLink, GlAvatar, GlTooltipDirective } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    GlAvatarLink,
    GlAvatar,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
  },
};
</script>
<template>
  <div class="pipeline-triggerer" data-testid="pipeline-triggerer">
    <gl-avatar-link v-if="user" v-gl-tooltip :href="user.path" :title="user.name" class="gl-ml-3">
      <gl-avatar :size="32" :src="user.avatar_url" />
    </gl-avatar-link>

    <span v-else class="gl-ml-3">
      {{ s__('Pipelines|API') }}
    </span>
  </div>
</template>
