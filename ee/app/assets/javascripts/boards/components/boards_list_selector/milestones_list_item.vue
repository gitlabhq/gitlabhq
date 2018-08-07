<script>
export default {
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
  methods: {
    handleItemClick() {
      this.$emit('onItemSelect', this.item);
    },
  },
};
</script>

<template>
  <li
    class="filter-dropdown-item"
    @click="handleItemClick"
  >
    <button
      class="btn btn-link dropdown-user"
      type="button"
    >
      <div class="dropdown-user-details">
        <div :title="item.title">{{ item.title }}</div>
      </div>
    </button>
  </li>
</template>
