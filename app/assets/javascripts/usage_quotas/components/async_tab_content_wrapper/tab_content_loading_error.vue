<script>
import { GlAlert } from '@gitlab/ui';

export default {
  name: 'TabContentLoadingError',
  components: { GlAlert },
};
</script>

<template>
  <gl-alert
    class="gl-my-3"
    variant="danger"
    :dismissible="false"
    :title="s__('UsageQuotas|There was an error while loading the tab contents')"
  >
    {{ s__('UsageQuotas|Reload the page to try again') }}
  </gl-alert>
</template>
