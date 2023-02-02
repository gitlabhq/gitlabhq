<script>
import { GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  i18n: {
    title: s__('UserProfile|Groups'),
  },
  components: { GlTab },
};
</script>

<template>
  <gl-tab :title="$options.i18n.title">
    <!-- placeholder -->
  </gl-tab>
</template>
