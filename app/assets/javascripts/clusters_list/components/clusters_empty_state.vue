<script>
import { GlEmptyState, GlLink, GlSprintf, GlAlert } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import PromoPageLink from '~/vue_shared/components/promo_page_link/promo_page_link.vue';
import { I18N_CLUSTERS_EMPTY_STATE } from '../constants';

export default {
  i18n: I18N_CLUSTERS_EMPTY_STATE,
  components: {
    GlEmptyState,
    GlLink,
    GlSprintf,
    GlAlert,
    PromoPageLink,
  },
  inject: ['emptyStateHelpText', 'clustersEmptyStateImage'],
  clustersHelpUrl: helpPagePath('user/infrastructure/clusters/_index', {
    anchor: 'certificate-based-kubernetes-integration-deprecated',
  }),
  blogPostPath: 'blog/2021/11/15/deprecating-the-cert-based-kubernetes-integration/',
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
          <promo-page-link :path="$options.blogPostPath" target="_blank">
            {{ content }}
          </promo-page-link>
        </template>
      </gl-sprintf>
    </gl-alert>
  </div>
</template>
