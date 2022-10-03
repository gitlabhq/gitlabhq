<script>
import { EXTENSION_ICONS } from '../../constants';
import StatusIcon from './status_icon.vue';

export default {
  components: {
    StatusIcon,
  },
  props: {
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
  <div class="gl-display-flex gl-align-items-baseline gl-w-full">
    <status-icon v-if="statusIconName" :level="2" :name="widgetName" :icon-name="statusIconName" />
    <slot name="default"></slot>
  </div>
</template>
