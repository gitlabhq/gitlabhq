<script>
import { GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'OrganizationProjectsEditApp',
  components: { GlSprintf },
  i18n: {
    pageTitle: __('Edit project: %{project_name}'),
  },
  inject: ['project'],
};
</script>

<template>
  <div class="gl-py-6">
    <h1 class="gl-mt-0 gl-font-size-h-display">
      <gl-sprintf :message="$options.i18n.pageTitle">
        <template #project_name>{{ project.fullName }}</template>
      </gl-sprintf>
    </h1>
  </div>
</template>
