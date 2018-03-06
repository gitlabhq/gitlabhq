<script>
  import icon from '../../../vue_shared/components/icon.vue';

  export default {
    components: {
      icon,
    },
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
      warningIcon() {
        if (this.isConfidential) return 'eye-slash';
        if (this.isLocked) return 'lock';

        return '';
      },
      isLockedAndConfidential() {
        return this.isConfidential && this.isLocked;
      },
    },
  };
</script>
<template>
  <div class="issuable-note-warning">
    <icon
      :name="warningIcon"
      :size="16"
      class="icon inline"
      aria-hidden="true"
      v-if="!isLockedAndConfidential"
    />

    <span v-if="isLockedAndConfidential">
      {{ __('This issue is confidential and locked.') }}
      {{ __(`People without permission will never
get a notification and won't be able to comment.`) }}
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
