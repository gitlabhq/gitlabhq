<script>
import { GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlIcon,
  },
  props: {
    placeholderText: {
      type: String,
      required: true,
      default: __('Search'),
    },
    focused: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return { searchQuery: this.value };
  },
  watch: {
    searchQuery(query) {
      this.$emit('input', query);
    },
    focused(val) {
      if (val) {
        this.$refs.searchInput.focus();
      }
    },
  },
};
</script>

<template>
  <div class="dropdown-input">
    <input
      ref="searchInput"
      v-model="searchQuery"
      :placeholder="placeholderText"
      class="dropdown-input-field"
      type="search"
      autocomplete="off"
    />
    <gl-icon name="search" class="dropdown-input-search" data-hidden="true" />
  </div>
</template>
