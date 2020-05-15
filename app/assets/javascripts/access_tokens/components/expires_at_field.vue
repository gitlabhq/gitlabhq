<script>
import { GlDatepicker } from '@gitlab/ui';

export default {
  name: 'ExpiresAtField',
  components: { GlDatepicker },
};
</script>

<template>
  <gl-datepicker :target="null" :min-date="new Date()">
    <slot></slot>
  </gl-datepicker>
</template>
