<script>
import { GlDatepicker, GlFormInput } from '@gitlab/ui';

export default {
  name: 'ExpiresAtField',
  components: { GlDatepicker, GlFormInput },
  props: {
    inputAttrs: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      minDate: new Date(),
    };
  },
};
</script>

<template>
  <gl-datepicker :target="null" :min-date="minDate">
    <gl-form-input
      v-bind="inputAttrs"
      class="datepicker gl-datepicker-input"
      autocomplete="off"
      inputmode="none"
      data-qa-selector="expiry_date_field"
    />
  </gl-datepicker>
</template>
