<script>
import { GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import AccessSummary from './access_summary.vue';

export default {
  components: { AccessSummary, GlIcon },
  i18n: {
    fullAccess: s__('AdminUsers|Full read and write access.'),
  },
};
</script>

<template>
  <access-summary>
    <template #admin-content>
      <gl-icon name="check" variant="success" />
      {{ $options.i18n.fullAccess }}
    </template>

    <template #group-content>
      <gl-icon name="check" variant="success" />
      {{ $options.i18n.fullAccess }}
    </template>

    <template #settings-content>
      <gl-icon name="check" variant="success" />
      {{ $options.i18n.fullAccess }}
    </template>
  </access-summary>
</template>
