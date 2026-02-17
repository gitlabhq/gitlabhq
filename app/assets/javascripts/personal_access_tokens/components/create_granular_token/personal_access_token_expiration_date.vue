<script>
import { GlFormGroup, GlSprintf, GlDatepicker, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { localeDateFormat, setUTCTime } from '~/lib/utils/datetime_utility';
import { defaultDate } from '~/vue_shared/access_tokens/utils';
import { s__, __ } from '~/locale';

export default {
  name: 'PersonalAccessTokenExpirationDate',
  components: {
    GlFormGroup,
    GlSprintf,
    GlDatepicker,
    GlLink,
  },
  inject: ['accessTokenMaxDate', 'accessTokenMinDate'],
  props: {
    value: {
      type: Date,
      required: false,
      default: null,
    },
    error: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['input'],
  data() {
    const maxExpirationDate = this.accessTokenMaxDate && setUTCTime(this.accessTokenMaxDate);
    const minExpirationDate = setUTCTime(this.accessTokenMinDate);

    return {
      maxExpirationDate,
      minExpirationDate,
    };
  },
  computed: {
    defaultExpirationDate() {
      return defaultDate(this.maxExpirationDate);
    },
    formattedMaxDate() {
      return localeDateFormat.asDate.format(this.maxExpirationDate);
    },
    daysBetween() {
      const today = setUTCTime(new Date());
      const diffInMilliseconds = this.maxExpirationDate - today;
      return Math.floor(diffInMilliseconds / (1000 * 60 * 60 * 24));
    },
  },
  mounted() {
    if (!this.value) {
      this.$emit('input', this.defaultExpirationDate);
    }
  },
  methods: {},
  i18n: {
    expirationDateLabel: s__('AccessTokens|Expiration date'),
    maxTokenLifetime: s__(
      'AccessTokens|An administrator has set the %{linkStart}maximum expiration date%{linkEnd} to %{days} days (%{maxDate}).',
    ),
    clearDate: __('Clear the date to create access tokens without expiration.'),
  },
  tokenLifetimeHelpPage: helpPagePath('administration/settings/account_and_limit_settings', {
    anchor: 'limit-the-lifetime-of-access-tokens',
  }),
};
</script>

<template>
  <gl-form-group
    :label="$options.i18n.expirationDateLabel"
    label-for="token-expiration"
    :invalid-feedback="error"
    :state="!error"
  >
    <template #description>
      <span v-if="maxExpirationDate">
        <gl-sprintf :message="$options.i18n.maxTokenLifetime">
          <template #days>{{ daysBetween }}</template>
          <template #maxDate>{{ formattedMaxDate }}</template>
          <template #link="{ content }">
            <gl-link :href="$options.tokenLifetimeHelpPage">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </span>
      <span v-else>
        {{ $options.i18n.clearDate }}
      </span>
    </template>

    <gl-datepicker
      :value="value"
      :default-date="defaultExpirationDate"
      :show-clear-button="!maxExpirationDate"
      :max-date="maxExpirationDate"
      :min-date="minExpirationDate"
      :state="!error"
      @input="$emit('input', $event)"
      @clear="$emit('input', $event)"
    />
  </gl-form-group>
</template>
