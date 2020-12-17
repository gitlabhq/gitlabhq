<script>
import { GlLink, GlAlert } from '@gitlab/ui';
import { __, s__ } from '~/locale';
/**
 * Renders Unmet Prerequisites block for job's view.
 */
export default {
  i18n: {
    failMessage: s__(
      'Job|This job failed because the necessary resources were not successfully created.',
    ),
    moreInformation: __('More information'),
  },
  components: {
    GlLink,
    GlAlert,
  },
  props: {
    helpPath: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <gl-alert variant="danger" class="gl-mt-3" :dismissible="false">
    {{ $options.i18n.failMessage }}
    <gl-link :href="helpPath">
      {{ $options.i18n.moreInformation }}
    </gl-link>
  </gl-alert>
</template>
