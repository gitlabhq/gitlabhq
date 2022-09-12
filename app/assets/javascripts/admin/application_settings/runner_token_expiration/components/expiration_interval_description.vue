<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';

export default {
  components: {
    GlLink,
    GlSprintf,
  },
  props: {
    message: {
      type: String,
      required: true,
    },
  },
  i18n: {
    fieldHelpText: s__(
      'AdminSettings|If no unit is written, it defaults to seconds. For example, these are all equivalent: %{oneDayInSeconds}, %{oneDayInHoursHumanReadable}, or %{oneDayHumanReadable}. Minimum value is two hours. %{linkStart}Learn more.%{linkEnd}',
    ),
  },
  computed: {
    helpUrl() {
      return helpPagePath('ci/runners/configure_runners', {
        anchor: 'authentication-token-security',
      });
    },
  },
};
</script>
<template>
  <p>
    {{ message }}
    <gl-sprintf :message="$options.i18n.fieldHelpText">
      <template #oneDayInSeconds>
        <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
        <code>86400</code>
      </template>
      <template #oneDayInHoursHumanReadable>
        <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
        <code>24 hours</code>
      </template>
      <template #oneDayHumanReadable>
        <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
        <code>1 day</code>
      </template>
      <template #link>
        <gl-link :href="helpUrl" target="_blank">{{ __('Learn more.') }}</gl-link>
      </template>
    </gl-sprintf>
  </p>
</template>
