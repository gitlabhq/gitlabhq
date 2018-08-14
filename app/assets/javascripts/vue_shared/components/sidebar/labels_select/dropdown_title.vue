<script>
export default {
  props: {
    canEdit: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <div class="title hide-collapsed append-bottom-10">
    {{ __('Labels') }}
    <template v-if="canEdit">
      <i
        aria-hidden="true"
        class="fa fa-spinner fa-spin block-loading"
        data-hidden="true"
      >
      </i>
      <button
        type="button"
        class="edit-link btn btn-blank float-right js-sidebar-dropdown-toggle"
      >
        {{ __('Edit') }}
      </button>
    </template>
  </div>
</template>
