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
    isGroupOpen: {
      type: Boolean,
      required: true,
      default: false,
    },
  },
  computed: {
    iconClass() {
      if (this.itemType === ITEM_TYPE.GROUP) {
        return this.isGroupOpen ? 'folder-open' : 'folder-o';
      }
      return 'bookmark';
    },
  },
};
</script>

<template>
  <span class="item-type-icon"> <gl-icon :name="iconClass" /> </span>
</template>
