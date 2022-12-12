<script>
import { GlButton, GlLink } from '@gitlab/ui';
import { OAUTH_SELF_MANAGED_DOC_LINK } from '~/jira_connect/subscriptions/constants';

export default {
  components: {
    GlButton,
    GlLink,
  },
  OAUTH_SELF_MANAGED_DOC_LINK,
};
</script>

<template>
  <div class="gl-max-w-62 gl-mx-auto gl-mt-7">
    <h3>{{ s__('JiraService|Continue setup in GitLab') }}</h3>
    <p>
      {{
        s__(
          'JiraService|In order to complete the set up, you’ll need to complete a few steps in GitLab.',
        )
      }}
      <gl-link
        class="gl-reset-font-size!"
        :href="$options.OAUTH_SELF_MANAGED_DOC_LINK"
        target="_blank"
        >{{ __('Learn more') }}</gl-link
      >
    </p>

    <gl-button variant="confirm" @click="$emit('next')">
      {{ __('Next') }}
    </gl-button>
  </div>
</template>
