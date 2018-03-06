<script>
export default {};
</script>

<template>
  <div class="dropdown-input">
    <input
      autocomplete="off"
      class="dropdown-input-field"
      type="search"
      :placeholder="__('Search')"
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
