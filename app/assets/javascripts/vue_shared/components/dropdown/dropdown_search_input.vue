<script>
import { __ } from '~/locale';

export default {
  props: {
    placeholderText: {
      type: String,
      required: true,
      default: __('Search'),
    },
  },
  data() {
    return { searchQuery: this.value };
  },
  watch: {
    searchQuery(query) {
      this.$emit('input', query);
    },
  },
};
</script>

<template>
  <div class="dropdown-input">
    <input
      class="dropdown-input-field"
      type="search"
      v-model="searchQuery"
      :placeholder="placeholderText"
      autocomplete="off"
    />
    <i
      aria-hidden="true"
      class="fa fa-search dropdown-input-search"
      data-hidden="true"
    >
    </i>
    <i
      aria-hidden="true"
      class="fa fa-times dropdown-input-clear js-dropdown-input-clear"
      data-hidden="true"
      role="button"
    >
    </i>
  </div>
</template>
