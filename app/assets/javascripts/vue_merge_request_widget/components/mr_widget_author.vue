<script>
import { GlAvatar, GlLink, GlTooltipDirective } from '@gitlab/ui';

export default {
  name: 'MrWidgetAuthor',
  components: {
    GlAvatar,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    author: {
      type: Object,
      required: true,
    },
    showAuthorName: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    authorUrl() {
      return this.author.webUrl || this.author.web_url;
    },
    avatarUrl() {
      return this.author.avatarUrl || this.author.avatar_url || gl.mrWidgetData.defaultAvatarUrl;
    },
  },
};
</script>
<template>
  <gl-link
    v-gl-tooltip
    :href="authorUrl"
    :title="showAuthorName ? null : author.name"
    class="mr-widget-author"
  >
    <gl-avatar :src="avatarUrl" :size="16" :alt="author.name" /><span
      v-if="showAuthorName"
      class="author gl-ml-2"
      >{{ author.name }}</span
    >
  </gl-link>
</template>
