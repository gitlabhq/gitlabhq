<script>
import { GlBanner, GlLink } from '@gitlab/ui';
import ChatBubbleSvg from '@gitlab/svgs/dist/illustrations/chat-sm.svg?url';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { CATALOG_FEEDBACK_DISMISSED_KEY } from '../../constants';

const defaultTitle = __('CI/CD Catalog');
const defaultDescription = s__(
  'CiCatalog|Discover CI/CD components that can improve your pipeline with additional functionality.',
);

export default {
  components: {
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
  learnMorePath: helpPagePath('ci/components/_index'),
  ChatBubbleSvg,
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
      :svg-path="$options.ChatBubbleSvg"
      @close="handleDismissBanner"
    >
      <p>
        {{ $options.i18n.banner.description }}
      </p>
    </gl-banner>
    <h1 class="page-title gl-text-size-h-display">{{ pageTitle }}</h1>
    <p>
      <span data-testid="page-description">{{ pageDescription }}</span>
      <gl-link :href="$options.learnMorePath" target="_blank">{{
        $options.i18n.learnMore
      }}</gl-link>
    </p>
  </div>
</template>
