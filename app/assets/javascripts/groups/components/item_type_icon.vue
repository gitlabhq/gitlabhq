<script>
import icon from '~/vue_shared/components/icon.vue';
import { ITEM_TYPE } from '../constants';

export default {
  components: {
    icon,
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
        return this.isGroupOpen ? 'folder-open' : 'folder';
      }
      return 'bookmark';
    },
  },
};
</script>

<template>
  <span class="item-type-icon">
    <icon :name="iconClass"/>
  </span>
</template>
