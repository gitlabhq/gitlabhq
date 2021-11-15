<script>
import { GlEmptyState, GlButton, GlLink, GlSprintf } from '@gitlab/ui';
import { mapState } from 'vuex';
import { helpPagePath } from '~/helpers/help_page_helper';
import { I18N_CLUSTERS_EMPTY_STATE } from '../constants';

export default {
  i18n: I18N_CLUSTERS_EMPTY_STATE,
  components: {
    GlEmptyState,
    GlButton,
    GlLink,
    GlSprintf,
  },
  inject: ['emptyStateHelpText', 'clustersEmptyStateImage', 'newClusterPath'],
  props: {
    isChildComponent: {
      default: false,
      required: false,
      type: Boolean,
    },
  },
  learnMoreHelpUrl: helpPagePath('user/project/clusters/index'),
  multipleClustersHelpUrl: helpPagePath('user/project/clusters/multiple_kubernetes_clusters'),
  computed: {
    ...mapState(['canAddCluster']),
  },
};
</script>

<template>
  <gl-empty-state :svg-path="clustersEmptyStateImage" title="">
    <template #description>
      <p class="gl-text-left">
        {{ $options.i18n.description }}
      </p>
      <p class="gl-text-left">
        <gl-sprintf :message="$options.i18n.multipleClustersText">
          <template #link="{ content }">
            <gl-link
              :href="$options.multipleClustersHelpUrl"
              target="_blank"
              data-testid="multiple-clusters-docs-link"
            >
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
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
        v-if="!isChildComponent"
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
