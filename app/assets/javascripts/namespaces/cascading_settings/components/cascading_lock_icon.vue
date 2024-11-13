<script>
import { GlIcon, GlButton } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { s__ } from '~/locale';
import LockTooltip from './lock_tooltip.vue';

export default {
  name: 'CascadingLockIcon',
  i18n: {
    lockIconLabel: s__('CascadingSettings|Lock tooltip icon'),
  },
  components: {
    GlIcon,
    GlButton,
    LockTooltip,
  },
  props: {
    ancestorNamespace: {
      type: Object,
      required: false,
      default: null,
      validator: (value) => value?.path && value?.fullName,
    },
    isLockedByApplicationSettings: {
      type: Boolean,
      required: true,
    },
    isLockedByGroupAncestor: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      targetElement: null,
    };
  },
  async mounted() {
    // Wait until all children components are mounted
    await this.$nextTick();
    this.targetElement = this.$refs[this.$options.refName].$el;
  },
  refName: uniqueId('cascading-lock-icon-'),
};
</script>

<template>
  <span>
    <gl-button :ref="$options.refName" class="!gl-p-0 hover:!gl-bg-transparent" category="tertiary">
      <gl-icon name="lock" :aria-label="$options.i18n.lockIconLabel" variant="subtle" />
    </gl-button>
    <lock-tooltip
      v-if="targetElement"
      :ancestor-namespace="ancestorNamespace"
      :is-locked-by-admin="isLockedByApplicationSettings"
      :is-locked-by-group-ancestor="isLockedByGroupAncestor"
      :target-element="targetElement"
    />
  </span>
</template>
