<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';

export default {
  i18n: {
    title: s__('ClusterIntegration|Enter your Kubernetes cluster certificate details'),
    information: s__(
      'ClusterIntegration|Enter details about your cluster. %{linkStart}How do I use a certificate to connect to my cluster?%{linkEnd}',
    ),
  },
  clusterConnectHelpPath: helpPagePath('user/project/clusters/add_existing_cluster'),
  components: {
    GlLink,
    GlSprintf,
  },
};
</script>

<template>
  <div class="gl-pt-4">
    <h4>{{ $options.i18n.title }}</h4>
    <p>
      <gl-sprintf :message="$options.i18n.information">
        <template #link="{ content }">
          <gl-link :href="$options.clusterConnectHelpPath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
  </div>
</template>
