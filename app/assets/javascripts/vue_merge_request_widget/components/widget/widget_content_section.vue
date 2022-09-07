<script>
import { EXTENSION_ICONS } from '../../constants';
import StatusIcon from '../extensions/status_icon.vue';

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
  <div class="gl-px-7">
    <div class="gl-pl-4 gl-display-flex">
      <status-icon
        v-if="statusIconName"
        :level="2"
        :name="widgetName"
        :icon-name="statusIconName"
      />
      <slot name="default"></slot>
    </div>
  </div>
</template>
