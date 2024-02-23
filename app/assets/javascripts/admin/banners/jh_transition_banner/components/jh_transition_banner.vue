<script>
import { GlBanner, GlSprintf, GlLink } from '@gitlab/ui';
import ClusterPopoverSvg from '@gitlab/svgs/dist/illustrations/devops-sm.svg?url';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import { transitionBannerTexts } from '../constants';

export default {
  name: 'JHTransitionBanner',
  components: {
    GlBanner,
    GlSprintf,
    GlLink,
    UserCalloutDismisser,
  },
  props: {
    userPreferredLanguage: {
      type: String,
      required: true,
    },
    featureName: {
      type: String,
      required: true,
    },
  },
  computed: {
    buttonAttributes() {
      return {
        target: '_blank',
      };
    },
    shouldShowBanner() {
      return (
        this.userPreferredLanguage.startsWith('zh') ||
        navigator.languages.some((lang) => lang.startsWith('zh'))
      );
    },
  },
  ClusterPopoverSvg,
  i18n: transitionBannerTexts,
};
</script>

<template>
  <user-callout-dismisser v-if="shouldShowBanner" :feature-name="featureName" skip-query>
    <template #default="{ shouldShowCallout, dismiss }">
      <gl-banner
        v-if="shouldShowCallout"
        :title="$options.i18n.title"
        :button-attributes="buttonAttributes"
        :button-text="$options.i18n.buttonText"
        :svg-path="$options.ClusterPopoverSvg"
        button-link="https://gitlab.cn/upgrade/"
        class="gl-mt-3"
        @close="dismiss"
      >
        <p>
          <gl-sprintf :message="$options.i18n.content">
            <template #link="{ content }">
              <gl-link href="https://gitlab.cn" target="_blank">
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </p>
      </gl-banner>
    </template>
  </user-callout-dismisser>
</template>
