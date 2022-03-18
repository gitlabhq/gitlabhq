<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { mapState } from 'vuex';
import { s__ } from '~/locale';

export default {
  i18n: {
    title: s__('ClusterIntegration|Enter your Kubernetes cluster certificate details'),
    information: s__(
      'ClusterIntegration|Enter details about your cluster. %{linkStart}How do I use a certificate to connect to my cluster?%{linkEnd}',
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
  <div class="gl-pt-4">
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
