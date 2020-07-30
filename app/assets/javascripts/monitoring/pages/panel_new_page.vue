<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import routes from '../router/constants';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  i18n: {
    backToDashboard: s__('Metrics|Back to dashboard'),
  },
  routes,
};
</script>
<template>
  <div class="gl-display-flex gl-align-items-baseline">
    <gl-button
      v-gl-tooltip
      icon="go-back"
      :to="{ name: $options.routes.DASHBOARD_PAGE, params: { dashboard: $route.params.dashboard } }"
      :aria-label="$options.i18n.backToDashboard"
      :title="$options.i18n.backToDashboard"
      class="gl-mr-5"
    />
    <h1 class="gl-mt-5 gl-font-size-h1">{{ s__('Metrics|Add panel') }}</h1>

    <!-- TODO: Add components. See https://gitlab.com/groups/gitlab-org/-/epics/2882  -->
  </div>
</template>
