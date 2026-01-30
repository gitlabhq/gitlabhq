<script>
import { GlLink } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

const defaultTitle = __('CI/CD Catalog');
const defaultDescription = s__(
  'CiCatalog|Discover CI/CD components that can improve your pipeline with additional functionality.',
);

export default {
  name: 'CatalogHeader',
  components: {
    GlLink,
  },
  inject: {
    pageTitle: { default: defaultTitle },
    pageDescription: {
      default: defaultDescription,
    },
    legalDisclaimer: { default: '' },
  },
  i18n: {
    learnMore: __('Learn more'),
  },
  learnMorePath: helpPagePath('ci/components/_index'),
};
</script>
<template>
  <div class="page-title-holder">
    <h1 class="page-title gl-text-size-h-display">{{ pageTitle }}</h1>
    <p class="gl-mb-3">
      <span data-testid="page-description">{{ pageDescription }}</span>
      <gl-link :href="$options.learnMorePath" target="_blank">{{
        $options.i18n.learnMore
      }}</gl-link>
    </p>
    <p v-if="legalDisclaimer" data-testid="legal-disclaimer" class="gl-text-sm gl-text-subtle">
      {{ legalDisclaimer }}
    </p>
  </div>
</template>
