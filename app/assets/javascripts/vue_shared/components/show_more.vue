<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: { GlButton },
  props: {
    limit: {
      required: true,
      type: Number,
    },
    items: {
      required: true,
      type: Array,
    },
  },
  data() {
    return { showMore: false };
  },
  computed: {
    listedItems() {
      return this.showMore ? this.items : this.items.slice(0, this.limit);
    },
    biggerThanLimit() {
      return this.items.length > this.limit;
    },
  },
  methods: {
    toggle() {
      this.showMore = !this.showMore;
    },
  },
  i18n: {
    showMore: __('Show more'),
    showLess: __('Show less'),
  },
};
</script>
<template>
  <div>
    <template v-for="(item, i) in listedItems">
      <slot :item="item" :is-last="i + 1 === listedItems.length"></slot>
    </template>
    <gl-button v-if="biggerThanLimit" variant="link" @click="toggle">{{
      showMore ? $options.i18n.showLess : $options.i18n.showMore
    }}</gl-button>
  </div>
</template>
