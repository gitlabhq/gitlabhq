<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlAlert,
    GlLink,
    GlSprintf,
  },
  inject: ['autoDevopsHelpPagePath'],
  i18n: {
    body: s__(
      'AutoDevopsAlert|Security testing tools enabled with %{linkStart}Auto DevOps%{linkEnd}',
    ),
  },
};
</script>

<template>
  <gl-alert variant="success" @dismiss="$emit('dismiss')">
    <gl-sprintf :message="$options.i18n.body">
      <template #link="{ content }">
        <gl-link :href="autoDevopsHelpPagePath">
          {{ content }}
        </gl-link>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
