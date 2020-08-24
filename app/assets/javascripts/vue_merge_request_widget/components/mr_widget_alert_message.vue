<script>
import { GlLink, GlIcon } from '@gitlab/ui';
import { WARNING, DANGER, WARNING_MESSAGE_CLASS, DANGER_MESSAGE_CLASS } from '../constants';

export default {
  name: 'MrWidgetAlertMessage',
  components: {
    GlLink,
    GlIcon,
  },
  props: {
    type: {
      type: String,
      required: false,
      default: DANGER,
      validator: value => [WARNING, DANGER].includes(value),
    },
    helpPath: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  computed: {
    messageClass() {
      if (this.type === WARNING) {
        return WARNING_MESSAGE_CLASS;
      } else if (this.type === DANGER) {
        return DANGER_MESSAGE_CLASS;
      }

      return '';
    },
  },
};
</script>

<template>
  <div class="m-3 ml-7" :class="messageClass">
    <slot></slot>
    <gl-link v-if="helpPath" :href="helpPath" target="_blank">
      <gl-icon :size="16" name="question-o" class="align-middle" />
    </gl-link>
  </div>
</template>
