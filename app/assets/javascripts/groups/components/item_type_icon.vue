<script>
import { ITEM_TYPE } from '../constants';

export default {
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
        return this.isGroupOpen ? 'fa-folder-open' : 'fa-folder';
      }
      return 'fa-bookmark';
    },
  },
};
</script>

<template>
  <span class="item-type-icon">
    <i
      :class="iconClass"
      class="fa"
      aria-hidden="true"/>
  </span>
</template>
