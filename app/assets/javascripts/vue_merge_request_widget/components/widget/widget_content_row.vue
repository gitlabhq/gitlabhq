<script>
import { EXTENSION_ICONS } from '../../constants';
import ContentBody from './widget_content_body.vue';

export default {
  components: {
    ContentBody,
  },
  props: {
    level: {
      type: Number,
      required: true,
      validator: (value) => value === 2 || value === 3,
    },
    statusIconName: {
      type: String,
      default: '',
      required: false,
      validator: (value) => value === '' || Object.keys(EXTENSION_ICONS).includes(value),
    },
    widgetName: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div
    class="gl-w-full mr-widget-content-row"
    :class="{ 'gl-border-t gl-py-3 gl-pl-7': level === 2 }"
  >
    <slot name="header"></slot>
    <content-body :status-icon-name="statusIconName" :widget-name="widgetName">
      <slot name="body"></slot>
    </content-body>
  </div>
</template>
