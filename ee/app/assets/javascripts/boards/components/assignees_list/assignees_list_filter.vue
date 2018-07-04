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
    :class="{ 'has-value': !!query }"
    class="dropdown-input"
  >
    <input
      :placeholder="__('Search')"
      v-model.trim="query"
      type="search"
      class="dropdown-input-field"
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
