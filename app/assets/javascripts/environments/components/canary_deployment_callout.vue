<script>
import { GlButton, GlLink, GlIcon } from '@gitlab/ui';
import PersistentUserCallout from '~/persistent_user_callout';

export default {
  components: {
    GlButton,
    GlLink,
    GlIcon,
  },
  props: {
    canaryDeploymentFeatureId: {
      type: String,
      required: true,
    },
    userCalloutsPath: {
      type: String,
      required: true,
    },
    lockPromotionSvgPath: {
      type: String,
      required: true,
    },
    helpCanaryDeploymentsPath: {
      type: String,
      required: true,
    },
  },
  mounted() {
    const callout = this.$refs['canary-deployment-callout'];
    PersistentUserCallout.factory(callout);
  },
};
</script>

<template>
  <div
    ref="canary-deployment-callout"
    class="p-3 canary-deployment-callout"
    :data-dismiss-endpoint="userCalloutsPath"
    :data-feature-id="canaryDeploymentFeatureId"
  >
    <img class="canary-deployment-callout-lock pr-3" :src="lockPromotionSvgPath" />

    <div class="pl-3">
      <p class="font-weight-bold mb-1">
        {{ __('Upgrade plan to unlock Canary Deployments feature') }}
      </p>

      <p class="canary-deployment-callout-message">
        {{
          __(
            'Canary Deployments is a popular CI strategy, where a small portion of the fleet is updated to the new version of your application.',
          )
        }}
        <gl-link :href="helpCanaryDeploymentsPath">{{ __('Read more') }}</gl-link>
      </p>

      <gl-button href="https://about.gitlab.com/sales/" category="secondary" variant="info">{{
        __('Contact sales to upgrade')
      }}</gl-button>
    </div>

    <div class="ml-auto pr-2 canary-deployment-callout-close js-close">
      <gl-icon name="close" />
    </div>
  </div>
</template>
