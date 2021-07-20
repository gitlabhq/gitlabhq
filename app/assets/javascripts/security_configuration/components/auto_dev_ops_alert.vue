<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlSprintf,
    GlAlert,
    GlLink,
  },
  inject: ['autoDevopsHelpPagePath', 'autoDevopsPath'],
  i18n: {
    primaryButtonText: s__('SecurityConfiguration|Enable Auto DevOps'),
    body: s__(
      'SecurityConfiguration|Quickly enable all continuous testing and compliance tools by enabling %{linkStart}Auto DevOps%{linkEnd}',
    ),
  },
  methods: {
    dismissMethod() {
      this.$emit('dismiss');
    },
  },
};
</script>

<template>
  <gl-alert
    variant="info"
    :primary-button-link="autoDevopsPath"
    :primary-button-text="$options.i18n.primaryButtonText"
    @dismiss="dismissMethod"
  >
    <gl-sprintf :message="$options.i18n.body">
      <template #link="{ content }">
        <gl-link :href="autoDevopsHelpPagePath">
          {{ content }}
        </gl-link>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
