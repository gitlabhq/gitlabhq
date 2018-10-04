<script>
export default {};
</script>

<template>
  <div class="dropdown-title">
    <span>{{ __('Assign labels') }}</span>
    <button
      :aria-label="__('Close')"
      type="button"
      class="dropdown-title-button dropdown-menu-close"
    >
      <i
        aria-hidden="true"
        class="fa fa-times dropdown-menu-close-icon"
        data-hidden="true"
      >
      </i>
    </button>
  </div>
</template>
