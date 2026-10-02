<script>
import { GlIcon, GlButton } from '@gitlab/ui';
import { uniqueId } from 'lodash-es';
import { s__ } from '~/locale';
import LockPopover from './lock_popover.vue';

export default {
  name: 'CascadingLockIcon',
  i18n: {
    lockIconLabel: s__('CascadingSettings|Lock popover icon'),
  },
  components: {
    GlIcon,
    GlButton,
    LockPopover,
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
    <lock-popover
      v-if="targetElement"
      :ancestor-namespace="ancestorNamespace"
      :is-locked-by-admin="isLockedByApplicationSettings"
      :is-locked-by-group-ancestor="isLockedByGroupAncestor"
      :target-element="targetElement"
    />
  </span>
</template>
