<script>
  export default {
    props: {
      isLocked: {
        type: Boolean,
        default: false,
        required: false,
      },

      isConfidential: {
        type: Boolean,
        default: false,
        required: false,
      },
    },

    computed: {
      iconClass() {
        return {
          'fa-eye-slash': this.isConfidential,
          'fa-lock': this.isLocked,
        };
      },

      isLockedAndConfidential() {
        return this.isConfidential && this.isLocked;
      },
    },
  };
</script>
<template>
  <div class="issuable-note-warning">
    <i
      aria-hidden="true"
      class="fa icon"
      :class="iconClass"
      v-if="!isLockedAndConfidential"
    ></i>

    <span v-if="isLockedAndConfidential">
      {{ __('This issue is confidential and locked.') }}
      {{ __('People without permission will never get a notification and won\'t be able to comment.') }}
    </span>

    <span v-else-if="isConfidential">
      {{ __('This is a confidential issue.') }}
      {{ __('Your comment will not be visible to the public.') }}
    </span>

    <span v-else-if="isLocked">
      {{ __('This issue is locked.') }}
      {{ __('Only project members can comment.') }}
    </span>
  </div>
</template>
