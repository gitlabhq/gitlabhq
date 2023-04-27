<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlLink,
    GlSprintf,
    SignInOauthButton: () => import('./sign_in_oauth_button.vue'),
  },
  inject: {
    gitlabUserPath: {
      default: '',
    },
  },
  props: {
    userSignedIn: {
      type: Boolean,
      required: true,
    },
    hasSubscriptions: {
      type: Boolean,
      required: true,
    },
    user: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    gitlabUserName() {
      return gon.current_username ?? this.user?.username;
    },
    gitlabUserHandle() {
      return this.gitlabUserName ? `@${this.gitlabUserName}` : undefined;
    },
    gitlabUserLink() {
      return this.gitlabUserPath ?? `${gon.relative_root_url}/${this.gitlabUserName}`;
    },
    signedInText() {
      return this.gitlabUserHandle
        ? this.$options.i18n.signedInAsUserText
        : this.$options.i18n.signedInText;
    },
  },
  i18n: {
    signInText: __('Sign in to GitLab'),
    signedInAsUserText: __('Signed in to GitLab as %{user_link}'),
    signedInText: __('Signed in to GitLab'),
  },
};
</script>
<template>
  <div class="gl-font-base">
    <gl-sprintf v-if="userSignedIn" :message="signedInText">
      <template #user_link>
        <gl-link data-testid="gitlab-user-link" :href="gitlabUserLink" target="_blank">
          {{ gitlabUserHandle }}
        </gl-link>
      </template>
    </gl-sprintf>

    <template v-else-if="hasSubscriptions">
      <sign-in-oauth-button category="tertiary">
        {{ $options.i18n.signInText }}
      </sign-in-oauth-button>
    </template>
  </div>
</template>
