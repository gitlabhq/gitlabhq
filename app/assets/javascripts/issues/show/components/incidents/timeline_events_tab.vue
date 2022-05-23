<script>
import { GlTab, GlButton } from '@gitlab/ui';

export default {
  components: {
    GlTab,
    GlButton,
  },
};
</script>

<template>
  <gl-tab :title="s__('Incident|Timeline')">
    <div class="gl-my-4">
      <p>{{ s__('Incident|No timeline items have been added yet.') }}</p>
    </div>
    <gl-button class="gl-my-3">
      {{ s__('Incident|Add new timeline event') }}
    </gl-button>
  </gl-tab>
</template>
