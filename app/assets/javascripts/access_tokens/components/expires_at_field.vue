<script>
import { GlDatepicker, GlFormGroup } from '@gitlab/ui';

import { __ } from '~/locale';
import { getDateInFuture } from '~/lib/utils/datetime_utility';

export default {
  name: 'ExpiresAtField',
  i18n: {
    label: __('Expiration date'),
  },
  components: {
    GlDatepicker,
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
    minDate: {
      type: Date,
      required: false,
      default: () => new Date(),
    },
    maxDate: {
      type: Date,
      required: false,
      default: () => null,
    },
  },
  computed: {
    in30Days() {
      const today = new Date();
      return getDateInFuture(today, 30);
    },
  },
};
</script>

<template>
  <gl-form-group :label="$options.i18n.label" :label-for="inputAttrs.id">
    <gl-datepicker
      :target="null"
      :min-date="minDate"
      :max-date="maxDate"
      :default-date="in30Days"
      show-clear-button
      :input-name="inputAttrs.name"
      :input-id="inputAttrs.id"
      :placeholder="inputAttrs.placeholder"
      data-qa-selector="expiry_date_field"
    />
    <template #description>
      <max-expiration-date-message :max-date="maxDate" />
    </template>
  </gl-form-group>
</template>
