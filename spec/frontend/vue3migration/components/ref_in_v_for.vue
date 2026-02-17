<script>
export default {
  name: 'RefInVFor',
  data() {
    return {
      items: ['a', 'b', 'c'],
    };
  },
  methods: {
    // eslint-disable-next-line vue/no-unused-properties
    getRefAtIndex(index) {
      const ref = this.$refs[`item-${index}`];
      return Array.isArray(ref) ? ref[0] : ref;
    },
  },
};
</script>

<template>
  <div>
    <span
      v-for="(item, index) in items"
      :key="item"
      :ref="`item-${index}`"
      :data-testid="`item-${index}`"
    >
      {{ item }}
    </span>
  </div>
</template>
