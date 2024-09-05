<script>
import { GlTooltipDirective, GlLink } from '@gitlab/ui';

export default {
  name: 'MrWidgetAuthor',
  components: {
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
    <img :src="avatarUrl" :alt="author.name" class="avatar avatar-inline s16" /><span
      v-if="showAuthorName"
      class="author"
      >{{ author.name }}</span
    >
  </gl-link>
</template>
