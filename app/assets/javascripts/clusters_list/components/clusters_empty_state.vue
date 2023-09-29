<script>
import { GlEmptyState, GlLink, GlSprintf, GlAlert } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { I18N_CLUSTERS_EMPTY_STATE } from '../constants';

export default {
  i18n: I18N_CLUSTERS_EMPTY_STATE,
  components: {
    GlEmptyState,
    GlLink,
    GlSprintf,
    GlAlert,
  },
  inject: ['emptyStateHelpText', 'clustersEmptyStateImage'],
  clustersHelpUrl: helpPagePath('user/infrastructure/clusters/index', {
    anchor: 'certificate-based-kubernetes-integration-deprecated',
  }),
  blogPostUrl:
    'https://about.gitlab.com/blog/2021/11/15/deprecating-the-cert-based-kubernetes-integration/',
};
</script>

<template>
  <div>
    <gl-empty-state
      :svg-path="clustersEmptyStateImage"
      :svg-height="100"
      data-testid="clusters-empty-state"
    >
      <template #title>
        <p>
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
    </gl-empty-state>

    <gl-alert variant="warning" :dismissible="false">
      <gl-sprintf :message="$options.i18n.alertText">
        <template #link="{ content }">
          <gl-link :href="$options.blogPostUrl" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>
  </div>
</template>
