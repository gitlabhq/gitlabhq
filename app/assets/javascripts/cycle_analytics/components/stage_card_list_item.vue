<script>
import Icon from '~/vue_shared/components/icon.vue';
import { GlButton } from '@gitlab/ui';

export default {
  name: 'StageCardListItem',
  components: {
    Icon,
    GlButton,
  },
  props: {
    isActive: {
      type: Boolean,
      required: true,
    },
    canEdit: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
};
</script>

<template>
  <div :class="{ active: isActive }" class="stage-nav-item d-flex pl-4 pr-4 m-0 mb-1 ml-2 rounded">
    <slot></slot>
    <div v-if="canEdit" class="dropdown">
      <gl-button
        :title="__('More actions')"
        class="more-actions-toggle btn btn-transparent p-0"
        data-toggle="dropdown"
      >
        <icon css-classes="icon" name="ellipsis_v" />
      </gl-button>
      <ul class="more-actions-dropdown dropdown-menu dropdown-open-left">
        <slot name="dropdown-options"></slot>
      </ul>
    </div>
  </div>
</template>
