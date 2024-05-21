<script>
import { GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'OrganizationGroupsEditApp',
  components: { GlSprintf },
  i18n: {
    pageTitle: __('Edit group: %{group_name}'),
  },
  inject: ['group'],
};
</script>

<template>
  <div class="gl-py-6">
    <h1 class="gl-mt-0 gl-font-size-h-display">
      <gl-sprintf :message="$options.i18n.pageTitle">
        <template #group_name>{{ group.fullName }}</template>
      </gl-sprintf>
    </h1>
  </div>
</template>
