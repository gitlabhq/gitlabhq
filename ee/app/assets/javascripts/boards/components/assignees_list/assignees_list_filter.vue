<script>
export default {
  data() {
    return {
      query: '',
    };
  },
  methods: {
    handleInputChange() {
      this.$emit('onSearchInput', this.query);
    },
    handleInputClear() {
      this.query = '';
      this.handleInputChange();
    },
  },
};
</script>

<template>
  <div
    class="dropdown-input"
    :class="{ 'has-value': !!query }"
  >
    <input
      type="search"
      class="dropdown-input-field"
      :placeholder="__('Search')"
      v-model.trim="query"
      @keyup="handleInputChange"
    />
    <i
      class="fa fa-search dropdown-input-search"
      aria-hidden="true"
      data-hidden="true"
    ></i>
    <i
      role="button"
      class="fa fa-times dropdown-input-clear"
      aria-hidden="true"
      data-hidden="true"
      @click="handleInputClear"
    ></i>
  </div>
</template>
