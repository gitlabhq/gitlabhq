<script>
  import tooltip from '~/vue_shared/directives/tooltip';
  import MrWidgetAuthor from './mr_widget_author.vue';

  export default {
    name: 'MrWidgetAuthorTime',
    components: {
      MrWidgetAuthor,
    },
    directives: {
      tooltip,
    },
    props: {
      actionText: {
        type: String,
        required: true,
      },
      author: {
        type: Object,
        required: true,
      },
      dateTitle: {
        type: String,
        required: true,
      },
      dateReadable: {
        type: String,
        required: true,
      },
    },
  };
</script>
<template>
  <h4 class="js-mr-widget-author">
    {{ actionText }}
    <mr-widget-author :author="author" />
    <time
      v-tooltip
      :title="dateTitle"
      data-container="body"
    >
      {{ dateReadable }}
    </time>
  </h4>
</template>
