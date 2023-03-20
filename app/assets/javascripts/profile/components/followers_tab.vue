<script>
import { GlBadge, GlTab } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  i18n: {
    title: s__('UserProfile|Followers'),
  },
  components: {
    GlBadge,
    GlTab,
  },
  inject: ['followers'],
};
</script>

<template>
  <gl-tab>
    <template #title>
      <span>{{ $options.i18n.title }}</span>
      <gl-badge size="sm" class="gl-ml-2">{{ followers }}</gl-badge>
    </template>
  </gl-tab>
</template>
