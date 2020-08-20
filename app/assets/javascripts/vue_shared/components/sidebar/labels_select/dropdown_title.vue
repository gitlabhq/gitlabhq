<script>
import { GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    GlLoadingIcon,
  },
  props: {
    canEdit: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <div class="title hide-collapsed gl-mb-3">
    {{ __('Labels') }}
    <template v-if="canEdit">
      <gl-loading-icon inline class="align-text-top block-loading" />
      <button
        type="button"
        class="edit-link btn btn-blank float-right js-sidebar-dropdown-toggle"
        data-qa-selector="labels_edit_button"
      >
        {{ __('Edit') }}
      </button>
    </template>
  </div>
</template>
