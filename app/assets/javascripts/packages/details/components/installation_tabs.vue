<script>
import Tracking from '~/tracking';
import { trackInstallationTabChange } from '../utils';
import { GlTab, GlTabs } from '@gitlab/ui';

export default {
  name: 'TabWrapper',
  components: {
    GlTab,
    GlTabs,
  },
  mixins: [Tracking.mixin(), trackInstallationTabChange],
  props: {
    trackingLabel: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="gl-mb-3">
    <gl-tabs @input="trackInstallationTabChange">
      <gl-tab :title="s__('PackageRegistry|Installation')" title-item-class="js-installation-tab">
        <div class="gl-ml-3 gl-mr-3">
          <slot name="installation"></slot>
        </div>
      </gl-tab>
      <gl-tab :title="s__('PackageRegistry|Registry Setup')" title-item-class="js-setup-tab">
        <div class="gl-ml-3 gl-mr-3">
          <slot name="setup"></slot>
        </div>
      </gl-tab>
    </gl-tabs>
  </div>
</template>
