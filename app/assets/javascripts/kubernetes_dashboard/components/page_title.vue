<script>
import { GlIcon, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  i18n: {
    agentTitle: s__('KubernetesDashboard|Agent %{name} ID #%{id}'),
  },
  components: {
    GlSprintf,
    GlIcon,
  },
  inject: ['agent'],
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center">
    <h1 class="gl-heading-2"><slot></slot></h1>
    <div class="gl-ml-4 gl-mb-5">
      <gl-icon name="kubernetes-agent" class="gl-text-gray-500" />
      <gl-sprintf :message="$options.i18n.agentTitle">
        <template #name> {{ agent.name }} </template>
        <template #id>{{ agent.id }}</template>
      </gl-sprintf>
    </div>
  </div>
</template>
