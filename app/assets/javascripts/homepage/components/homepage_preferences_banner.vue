<script>
import { GlBanner } from '@gitlab/ui';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';

export default {
  components: {
    GlBanner,
    UserCalloutDismisser,
  },
  preferencesLink: '/-/profile/preferences',
};
</script>

<template>
  <div>
    <user-callout-dismisser feature-name="personal_homepage_preferences_banner">
      <template #default="{ dismiss, shouldShowCallout }">
        <gl-banner
          v-if="shouldShowCallout"
          :title="s__('Homepage|Welcome to the new homepage')"
          class="homepage-duo-core-banner gl-mb-5 gl-bg-white"
          :button-text="s__('Homepage|Go to preferences')"
          :button-link="$options.preferencesLink"
          @close="dismiss"
        >
          <p>
            {{
              s__(
                "Homepage|We're introducing a new way for you to get an overview of your work, so you can plan what to work on next. The homepage is now the default for everyone. If you prefer to change your default homepage, you can update your user preferences.",
              )
            }}
          </p>
        </gl-banner>
      </template>
    </user-callout-dismisser>
  </div>
</template>

<style scoped>
.homepage-duo-core-banner {
  background-image: url('./homepage_banner_background.svg?url');
  background-size: cover;
  background-position: center;
  background-repeat: no-repeat;
}
</style>
