<script>
import { GlEmptyState, GlButton, GlLink } from '@gitlab/ui';
import { mapState } from 'vuex';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  i18n: {
    title: s__('ClusterIntegration|Integrate Kubernetes with a cluster certificate'),
    description: s__(
      'ClusterIntegration|Kubernetes clusters allow you to use review apps, deploy your applications, run your pipelines, and much more in an easy way.',
    ),
    learnMoreLinkText: s__('ClusterIntegration|Learn more about Kubernetes'),
    buttonText: s__('ClusterIntegration|Integrate with a cluster certificate'),
  },
  components: {
    GlEmptyState,
    GlButton,
    GlLink,
  },
  inject: ['emptyStateHelpText', 'clustersEmptyStateImage', 'newClusterPath'],
  learnMoreHelpUrl: helpPagePath('user/project/clusters/index'),
  computed: {
    ...mapState(['canAddCluster']),
  },
};
</script>

<template>
  <gl-empty-state :svg-path="clustersEmptyStateImage" :title="$options.i18n.title">
    <template #description>
      <p>
        {{ $options.i18n.description }}
      </p>

      <p v-if="emptyStateHelpText" data-testid="clusters-empty-state-text">
        {{ emptyStateHelpText }}
      </p>

      <p>
        <gl-link :href="$options.learnMoreHelpUrl" target="_blank" data-testid="clusters-docs-link">
          {{ $options.i18n.learnMoreLinkText }}
        </gl-link>
      </p>
    </template>

    <template #actions>
      <gl-button
        data-testid="integration-primary-button"
        data-qa-selector="add_kubernetes_cluster_link"
        category="primary"
        variant="confirm"
        :disabled="!canAddCluster"
        :href="newClusterPath"
      >
        {{ $options.i18n.buttonText }}
      </gl-button>
    </template>
  </gl-empty-state>
</template>
