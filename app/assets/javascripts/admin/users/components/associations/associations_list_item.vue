<script>
import { GlSprintf } from '@gitlab/ui';

export default {
  components: { GlSprintf },
  props: {
    message: {
      type: String,
      required: true,
    },
    count: {
      type: Number,
      required: true,
    },
  },
};
</script>

<template>
  <li>
    <gl-sprintf :message="message">
      <template #count>
        <strong>{{ count }}</strong>
      </template>
    </gl-sprintf>
  </li>
</template>
