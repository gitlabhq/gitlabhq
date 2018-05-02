<script>
import { __ } from '~/locale';

export default {
  props: {
    searchQuery: {
      type: String,
      required: false,
      default: '',
    },
    placeholderText: {
      type: String,
      required: true,
      default: __('Search'),
    },
  },
};
</script>

<template>
  <div class="dropdown-input">
    <input
      autocomplete="off"
      class="dropdown-input-field"
      type="search"
      :placeholder="placeholderText"
      :searchQuery="searchQuery"
      @input="$emit('input', $event.target.value)"
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
