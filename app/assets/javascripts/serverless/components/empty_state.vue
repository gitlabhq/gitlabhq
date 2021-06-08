<script>
import { GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import { mapState } from 'vuex';

export default {
  components: {
    GlEmptyState,
    GlLink,
    GlSprintf,
  },
  computed: {
    ...mapState(['emptyImagePath', 'helpPath']),
  },
};
</script>

<template>
  <gl-empty-state
    :svg-path="emptyImagePath"
    :title="s__('Serverless|Getting started with serverless')"
  >
    <template #description>
      <gl-sprintf
        :message="
          s__(
            'Serverless|In order to start using functions as a service, you must first install Knative on your Kubernetes cluster. %{linkStart}More information%{linkEnd}',
          )
        "
      >
        <template #link="{ content }">
          <gl-link :href="helpPath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
  </gl-empty-state>
</template>
