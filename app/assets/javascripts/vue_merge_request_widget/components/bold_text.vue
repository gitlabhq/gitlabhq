<script>
import { GlSprintf } from '@gitlab/ui';

export default {
  name: 'BoldText',
  components: {
    GlSprintf,
  },
  props: {
    message: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <span>
    <gl-sprintf :message="message">
      <template #bold="{ content }">
        <span class="gl-font-bold" v-text="content"></span>
      </template>
    </gl-sprintf>
  </span>
</template>
