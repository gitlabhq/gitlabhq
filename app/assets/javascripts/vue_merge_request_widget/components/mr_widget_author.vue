<script>
  export default {
    name: 'MRWidgetAuthor',
    props: {
      author: {
        type: Object,
        required: true,
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
  >
    <img
      :src="avatarUrl"
      class="avatar avatar-inline s16"
    />
    <span class="author">
      {{ author.name }}
    </span>
  </a>
</template>
