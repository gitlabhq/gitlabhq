<script>
  export default {
    props: {
      label: {
        type: String,
        required: false,
        default: 'Loading',
      },

      size: {
        type: String,
        required: false,
        default: '1',
      },
    },

    computed: {
      cssClass() {
        return `fa-${this.size}x`;
      },
    },
  };
</script>
<template>
  <div class="text-center">
    <i
      class="fa fa-spin fa-spinner"
      :class="cssClass"
      aria-hidden="true"
      :aria-label="label">
    </i>
  </div>
</template>
