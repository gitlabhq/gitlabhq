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
  <div class="gl-flex gl-w-full gl-items-center gl-px-5 gl-py-4">
    <gl-loading-icon size="sm" class="gl-pr-3" />
    <div class="gl-flex gl-items-center">
      {{ $options.i18n.preparing }}
    </div>
  </div>
</template>
