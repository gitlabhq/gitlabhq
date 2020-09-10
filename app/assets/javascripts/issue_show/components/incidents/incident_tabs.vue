<script>
import { GlTab, GlTabs } from '@gitlab/ui';
import DescriptionComponent from '../description.vue';
import HighlightBar from './highlight_bar/higlight_bar.vue';

export default {
  components: {
    GlTab,
    GlTabs,
    DescriptionComponent,
    HighlightBar,
  },
};
</script>

<template>
  <div>
    <gl-tabs content-class="gl-reset-line-height" class="gl-mt-n3" data-testid="incident-tabs">
      <gl-tab :title="__('Summary')">
        <highlight-bar />
        <description-component v-bind="$attrs" />
      </gl-tab>
    </gl-tabs>
  </div>
</template>
