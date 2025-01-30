<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlAvatar, GlAvatarLink, GlLink, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { escape } from 'lodash';

export default {
  components: {
    GlAvatar,
    GlAvatarLink,
    GlLink,
  },
  directives: {
    GlTooltip,
  },
  props: {
    commit: {
      required: true,
      type: Object,
    },
  },
  computed: {
    commitTitle() {
      return this.commit?.title;
    },
    commitAuthorPath() {
      return this.commit?.author?.path || `mailto:${escape(this.commit?.authorEmail)}`;
    },
    commitAuthorAvatar() {
      return this.commit?.author?.avatarUrl || this.commit?.authorGravatarUrl;
    },
    commitAuthor() {
      return this.commit?.author?.name || this.commit?.authorName;
    },
    commitPath() {
      return this.commit?.webPath || this.commit?.commitPath;
    },
  },
};
</script>
<template>
  <div data-testid="deployment-commit" class="gl-flex gl-items-center">
    <gl-avatar-link v-gl-tooltip :title="commitAuthor" :href="commitAuthorPath">
      <gl-avatar :size="16" :src="commitAuthorAvatar" />
    </gl-avatar-link>
    <gl-link
      v-gl-tooltip
      :title="commitTitle"
      :href="commitPath"
      class="gl-str-truncated gl-ml-3 gl-max-w-full"
    >
      {{ commitTitle }}
    </gl-link>
  </div>
</template>
