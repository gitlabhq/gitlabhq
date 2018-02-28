<script>
  import tooltip from '../../vue_shared/directives/tooltip';

  export default {
    name: 'MRWidgetAuthor',
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
    class="author-link inline"
    :v-tooltip="showAuthorTooltip"
    :title="author.name"
  >
    <img
      :src="avatarUrl"
      class="avatar avatar-inline s16"
    />
    <span
      class="author"
      v-if="showAuthorName"
    >
      {{ author.name }}
    </span>
  </a>
</template>
