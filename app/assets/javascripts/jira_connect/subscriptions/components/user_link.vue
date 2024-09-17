<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlLink,
    GlSprintf,
  },
  inject: {
    gitlabUserPath: {
      default: '',
    },
  },
  props: {
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
    signedInAsUserText: __('Signed in to GitLab as %{user_link}'),
    signedInText: __('Signed in to GitLab'),
  },
};
</script>

<template>
  <div class="gl-text-base">
    <gl-sprintf :message="signedInText">
      <template #user_link>
        <gl-link data-testid="gitlab-user-link" :href="gitlabUserLink" target="_blank">
          {{ gitlabUserHandle }}
        </gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>
