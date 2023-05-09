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
  <div class="gl-mt-5">
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

    <div class="gl-display-flex gl-justify-content-space-between">
      <gl-button @click="$emit('back')">{{ __('Back') }}</gl-button>
      <gl-button variant="confirm" @click="$emit('next')">{{ __('Next') }}</gl-button>
    </div>
  </div>
</template>
