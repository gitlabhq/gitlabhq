<script>
import { GlTab, GlTabs } from '@gitlab/ui';
import DescriptionComponent from './description.vue';

export default {
  components: {
    GlTab,
    GlTabs,
    DescriptionComponent,
  },
};
</script>

<template>
  <div>
    <gl-tabs
      content-class="gl-reset-line-height gl-mt-3"
      class="gl-mt-n3"
      data-testid="incident-tabs"
    >
      <gl-tab :title="__('Summary')">
        <description-component v-bind="$attrs" />
      </gl-tab>
    </gl-tabs>
  </div>
</template>
