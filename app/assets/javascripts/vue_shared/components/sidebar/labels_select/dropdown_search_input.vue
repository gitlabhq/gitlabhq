<script>
import { GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
};
</script>

<template>
  <div class="dropdown-input">
    <input
      :placeholder="__('Search')"
      autocomplete="off"
      class="dropdown-input-field"
      type="search"
    />
    <gl-icon
      name="search"
      class="dropdown-input-search gl-absolute gl-top-3 gl-right-5 gl-text-gray-300 gl-pointer-events-none"
    />
    <gl-icon
      name="close"
      class="dropdown-input-clear js-dropdown-input-clear gl-absolute gl-top-3 gl-right-5 gl-text-gray-500"
    />
  </div>
</template>
