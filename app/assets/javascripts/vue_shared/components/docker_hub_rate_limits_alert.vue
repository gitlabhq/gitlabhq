<script>
// This component and it's instances should be removed on 4/15/25
// See https://gitlab.com/gitlab-org/gitlab/-/issues/527721
import { GlAlert } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';

const DOCKER_HUB_KEY = 'docker_hub_rate_limits_dismissed';

export default {
  components: {
    GlAlert,
  },
  data() {
    return {
      isBannerDismissed: localStorage.getItem(DOCKER_HUB_KEY) === 'true',
    };
  },
  methods: {
    handleDismissBanner() {
      localStorage.setItem(DOCKER_HUB_KEY, 'true');
      this.isBannerDismissed = true;
    },
  },
  authenticatePath: helpPagePath('user/packages/dependency_proxy/_index', {
    anchor: 'authenticate-with-docker-hub',
  }),
};
</script>
<template>
  <gl-alert
    v-if="!isBannerDismissed"
    variant="warning"
    :primary-button-text="__('Authenticate with Docker Hub')"
    :primary-button-link="$options.authenticatePath"
    :secondary-button-text="__('Learn more')"
    secondary-button-link="https://about.gitlab.com/blog/2025/03/24/prepare-now-docker-hub-rate-limits-will-impact-gitlab-ci-cd"
    @dismiss="handleDismissBanner"
  >
    {{
      __(
        'Docker Hub pull rate limits begin April 1, 2025 and might affect CI/CD pipelines that pull Docker images. To prevent pipeline failures, configure the GitLab Dependency Proxy to authenticate with Docker Hub.',
      )
    }}
  </gl-alert>
</template>
