<script>
import { GlTooltipDirective } from '@gitlab/ui';
import MrWidgetAuthor from './mr_widget_author.vue';

export default {
  name: 'MrWidgetAuthorTime',
  components: {
    MrWidgetAuthor,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
  <h4 class="js-mr-widget-author gl-grow">
    {{ actionText }}
    <mr-widget-author :author="author" />
    <span class="sr-only">{{ dateReadable }} ({{ dateTitle }})</span>
    <time v-gl-tooltip.hover aria-hidden :title="dateTitle"> {{ dateReadable }} </time>
  </h4>
</template>
