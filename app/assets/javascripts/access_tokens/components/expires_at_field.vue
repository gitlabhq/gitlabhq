<script>
import { GlDatepicker, GlFormInput, GlFormGroup } from '@gitlab/ui';

import { __ } from '~/locale';

export default {
  name: 'ExpiresAtField',
  i18n: {
    label: __('Expiration date'),
  },
  components: {
    GlDatepicker,
    GlFormInput,
    GlFormGroup,
    MaxExpirationDateMessage: () =>
      import('ee_component/access_tokens/components/max_expiration_date_message.vue'),
  },
  props: {
    inputAttrs: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    maxDate: {
      type: Date,
      required: false,
      default: () => null,
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
  <gl-form-group :label="$options.i18n.label" :label-for="inputAttrs.id">
    <gl-datepicker :target="null" :min-date="minDate" :max-date="maxDate">
      <gl-form-input
        v-bind="inputAttrs"
        class="datepicker gl-datepicker-input"
        autocomplete="off"
        inputmode="none"
        data-qa-selector="expiry_date_field"
      />
    </gl-datepicker>
    <template #description>
      <max-expiration-date-message :max-date="maxDate" />
    </template>
  </gl-form-group>
</template>
