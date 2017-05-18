<script>
  export default {
    methods: {
      closeForm() {
        this.$emit('closeForm');
      },
    },
  };
</script>

<template>
  <div class="alert alert-danger">
    Someone edited the issue the same time you did. Please check out
    <a
      href="#"
      role="button"
      @click.prevent="closeForm">the issue</a>
    and make sure your changes will not unintentionally remove theirs.
  </div>
</template>
