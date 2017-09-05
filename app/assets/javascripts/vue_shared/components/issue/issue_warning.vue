<script>
  export default {
    props: {
      locked: {
        type: Boolean,
        default: false,
      },

      confidential: {
        type: Boolean,
        default: false,
      },
    },

    computed: {
      iconClass() {
        return {
          'fa-eye-slash': this.confidential,
          'fa-lock': this.locked,
        };
      },

      isLockedAndConfidential() {
        return this.confidential && this.locked;
      },
    },
  };
</script>
<template>
  <div class="issuable-note-warning">
    <i
    aria-hidden="true"
    class="fa"
    :class="iconClass"
    v-if="!isLockedAndConfidential">
    </i>

    <span v-if="isLockedAndConfidential">
      This issue is confidential and locked.
      People without permission will never get a notification and not be able to comment.
    </span>

    <span v-else-if="confidential">
      This is a confidential issue.
      Your comment will not be visible to the public.
    </span>

    <span v-else-if="locked">
      This issue is locked.
      Only project members can comment.
    </span>
  </div>
</template>
