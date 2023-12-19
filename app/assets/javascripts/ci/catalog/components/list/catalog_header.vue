<script>
import { GlBanner, GlLink } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import BetaBadge from '~/vue_shared/components/badges/beta_badge.vue';
import { CATALOG_FEEDBACK_DISMISSED_KEY } from '../../constants';

const defaultTitle = __('CI/CD Catalog');
const defaultDescription = s__(
  'CiCatalog|Discover CI/CD components that can improve your pipeline with additional functionality.',
);

export default {
  components: {
    BetaBadge,
    GlBanner,
    GlLink,
  },
  inject: {
    pageTitle: { default: defaultTitle },
    pageDescription: {
      default: defaultDescription,
    },
  },
  data() {
    return {
      isFeedbackBannerDismissed: localStorage.getItem(CATALOG_FEEDBACK_DISMISSED_KEY) === 'true',
    };
  },
  methods: {
    handleDismissBanner() {
      localStorage.setItem(CATALOG_FEEDBACK_DISMISSED_KEY, 'true');
      this.isFeedbackBannerDismissed = true;
    },
  },
  i18n: {
    banner: {
      title: __('Your feedback is important to us 👋'),
      description: s__(
        "CiCatalog|We want to help you create and manage pipeline component repositories, while also making it easier to reuse pipeline configurations. Let us know how we're doing!",
      ),
      btnText: __('Give us some feedback'),
    },
    learnMore: __('Learn more'),
  },
  learnMorePath: helpPagePath('ci/components/index'),
};
</script>
<template>
  <div class="page-title-holder">
    <gl-banner
      v-if="!isFeedbackBannerDismissed"
      class="gl-mt-5"
      :title="$options.i18n.banner.title"
      :button-text="$options.i18n.banner.btnText"
      button-link="https://gitlab.com/gitlab-org/gitlab/-/issues/407556"
      @close="handleDismissBanner"
    >
      <p>
        {{ $options.i18n.banner.description }}
      </p>
    </gl-banner>
    <div class="gl-my-4 gl-display-flex gl-align-items-center">
      <h1 class="gl-m-0 gl-font-size-h-display">{{ pageTitle }}</h1>
      <beta-badge class="gl-ml-3" />
    </div>
    <p>
      <span data-testid="page-description">{{ pageDescription }}</span>
      <gl-link :href="$options.learnMorePath" target="_blank">{{
        $options.i18n.learnMore
      }}</gl-link>
    </p>
  </div>
</template>
