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
    defaultDateOffset: {
      type: Number,
      required: false,
      default: 30,
    },
    description: {
      type: String,
      required: false,
      default: null,
    },
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
    defaultDate() {
      const defaultDate = getDateInFuture(new Date(), this.defaultDateOffset);
      // The maximum date can be set by admins. If the maximum date is sooner
      // than the default expiration date we use the maximum date as default
      // expiration date.
      if (this.maxDate && this.maxDate < defaultDate) {
        return this.maxDate;
      }
      return defaultDate;
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
      :default-date="defaultDate"
      show-clear-button
      :input-name="inputAttrs.name"
      :input-id="inputAttrs.id"
      :placeholder="inputAttrs.placeholder"
      data-testid="expiry-date-field"
    />
    <template #description>
      <template v-if="description">
        {{ description }}
      </template>
      <max-expiration-date-message v-else :max-date="maxDate" />
    </template>
  </gl-form-group>
</template>
