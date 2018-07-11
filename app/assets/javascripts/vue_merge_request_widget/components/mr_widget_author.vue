<script>
  import tooltip from '../../vue_shared/directives/tooltip';

  export default {
    name: 'MrWidgetAuthor',
    directives: {
      tooltip,
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
      showAuthorTooltip: {
        type: Boolean,
        required: false,
        default: false,
      },
    },
    computed: {
      authorUrl() {
        return this.author.webUrl || this.author.web_url;
      },
      avatarUrl() {
        return this.author.avatarUrl || this.author.avatar_url;
      },
    },
  };
</script>
<template>
  <a
    :href="authorUrl"
    :v-tooltip="showAuthorTooltip"
    :title="author.name"
    class="author-link inline"
  >
    <img
      :src="avatarUrl"
      class="avatar avatar-inline s16"
    />
    <span
      v-if="showAuthorName"
      class="author"
    >
      {{ author.name }}
    </span>
  </a>
</template>
