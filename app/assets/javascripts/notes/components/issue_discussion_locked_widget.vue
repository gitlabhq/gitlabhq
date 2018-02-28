<script>
  export default {
    computed: {
      lockIcon() {
        return gl.utils.spriteIcon('lock');
      },
    },
  };

</script>

<template>
  <div class="disabled-comment text-center">
    <span class="issuable-note-warning">
      <span class="icon" v-html="lockIcon"></span>
      <span>This issue is locked. Only <b>project members</b> can comment.</span>
     </span>
  </div>
</template>
