<script>
import { NAV_ITEM_LINK_ACTIVE_CLASS } from '../constants';
import { ariaCurrent } from '../utils';

export default {
  NAV_ITEM_LINK_ACTIVE_CLASS,
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
  computed: {
    linkProps() {
      return {
        to: this.item.to,
      };
    },
  },
  methods: {
    ariaCurrent,
  },
};
</script>

<template>
  <router-link
    #default="{ href, navigate, isActive }"
    v-bind="linkProps"
    :active-class="$options.NAV_ITEM_LINK_ACTIVE_CLASS"
    custom
  >
    <a :href="href" :aria-current="ariaCurrent(isActive)" @click="navigate">
      <slot :is-active="isActive"></slot>
    </a>
  </router-link>
</template>
