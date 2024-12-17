<script>
import { GlIcon } from '@gitlab/ui';
import { ITEM_TYPE } from '../constants';

export default {
  components: {
    GlIcon,
  },
  props: {
    itemType: {
      type: String,
      required: true,
    },
  },
  computed: {
    iconClass() {
      if (this.itemType === ITEM_TYPE.GROUP) {
        return 'subgroup';
      }
      return 'project';
    },
  },
};
</script>

<template>
  <span class="item-type-icon gl-inline-block">
    <gl-icon :name="iconClass" variant="subtle" />
  </span>
</template>
