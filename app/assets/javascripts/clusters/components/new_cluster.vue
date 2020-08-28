<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { mapState } from 'vuex';
import { s__ } from '~/locale';

export default {
  i18n: {
    title: s__('ClusterIntegration|Enter the details for your Kubernetes cluster'),
    information: s__(
      'ClusterIntegration|Please enter access information for your Kubernetes cluster. If you need help, you can read our %{linkStart}documentation%{linkEnd} on Kubernetes',
    ),
  },
  components: {
    GlLink,
    GlSprintf,
  },
  computed: {
    ...mapState(['clusterConnectHelpPath']),
  },
};
</script>

<template>
  <div>
    <h4>{{ $options.i18n.title }}</h4>
    <p>
      <gl-sprintf :message="$options.i18n.information">
        <template #link="{ content }">
          <gl-link :href="clusterConnectHelpPath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
  </div>
</template>
