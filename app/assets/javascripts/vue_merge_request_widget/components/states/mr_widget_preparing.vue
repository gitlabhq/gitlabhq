<script>
import { GlLoadingIcon } from '@gitlab/ui';

import { MR_WIDGET_PREPARING_ASYNCHRONOUSLY } from '../../i18n';

export default {
  name: 'MRWidgetPreparing',
  i18n: {
    preparing: MR_WIDGET_PREPARING_ASYNCHRONOUSLY,
  },
  components: {
    GlLoadingIcon,
  },
};
</script>
<template>
  <div class="gl-w-full gl-display-flex gl-p-4">
    <gl-loading-icon size="md" class="gl-pr-4" inline />
    <div class="gl-display-flex gl-align-items-center">
      {{ $options.i18n.preparing }}
    </div>
  </div>
</template>
