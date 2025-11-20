<script>
import { GlBanner, GlLink, GlSprintf } from '@gitlab/ui';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';

export default {
  name: 'HomepagePreferencesBanner',
  components: {
    GlBanner,
    GlLink,
    GlSprintf,
    UserCalloutDismisser,
  },
  inject: ['preferencesPath'],
  buttonAttributes: { hidden: true },
};
</script>

<template>
  <user-callout-dismisser feature-name="personal_homepage_preferences_banner">
    <template #default="{ dismiss, shouldShowCallout }">
      <gl-banner
        v-if="shouldShowCallout"
        data-testid="homepage-preferences-banner"
        :title="s__('Homepage|Welcome to the new homepage')"
        class="homepage-duo-core-banner gl-mb-5 gl-bg-white"
        button-text=""
        :button-attributes="$options.buttonAttributes"
        @close="dismiss"
      >
        <gl-sprintf
          :message="
            s__(
              `Homepage|We're introducing a new way for you to get an overview of your work, so you can plan what to work on next. The homepage is now the default for you. If you prefer to change your default homepage, you can %{linkStart}update your user preferences%{linkEnd}.`,
            )
          "
        >
          <template #link="{ content }">
            <gl-link :href="preferencesPath" data-testid="go-to-preferences-link">{{
              content
            }}</gl-link>
          </template>
        </gl-sprintf>
      </gl-banner>
    </template>
  </user-callout-dismisser>
</template>

<style scoped>
.homepage-duo-core-banner {
  background-image: url('./homepage_banner_background.svg?url');
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
}
</style>
