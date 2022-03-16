<script>
import { GlEmptyState, GlButton, GlLink, GlSprintf, GlAlert } from '@gitlab/ui';
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
    GlAlert,
  },
  inject: ['emptyStateHelpText', 'clustersEmptyStateImage', 'addClusterPath'],
  props: {
    isChildComponent: {
      default: false,
      required: false,
      type: Boolean,
    },
  },
  clustersHelpUrl: helpPagePath('user/infrastructure/clusters/index', {
    anchor: 'certificate-based-kubernetes-integration-deprecated',
  }),
  blogPostUrl:
    'https://about.gitlab.com/blog/2021/11/15/deprecating-the-cert-based-kubernetes-integration/',
  computed: {
    ...mapState(['canAddCluster']),
  },
};
</script>

<template>
  <div>
    <gl-empty-state :svg-path="clustersEmptyStateImage" title="">
      <template #description>
        <p class="gl-text-left">
          <gl-sprintf :message="$options.i18n.introText">
            <template #link="{ content }">
              <gl-link :href="$options.clustersHelpUrl">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </p>

        <p v-if="emptyStateHelpText" data-testid="clusters-empty-state-text">
          {{ emptyStateHelpText }}
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
          :href="addClusterPath"
        >
          {{ $options.i18n.buttonText }}
        </gl-button>
      </template>
    </gl-empty-state>

    <gl-alert variant="warning" :dismissible="false">
      <gl-sprintf :message="$options.i18n.alertText">
        <template #link="{ content }">
          <gl-link :href="$options.blogPostUrl" target="_blank">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>
  </div>
</template>
