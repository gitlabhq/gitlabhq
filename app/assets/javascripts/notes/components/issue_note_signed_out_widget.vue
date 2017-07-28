<script>
  export default {
    data() {
      const { newSessionPath, registerPath } = this.$store.getters.notesData;

      return {
        signInLink: newSessionPath,
        registerLink: registerPath,
      };
    },
  };
</script>

<template>
  <div class="disabled-comment text-center">
    Please
    <a :href="registerLink">register</a>
    or
    <a :href="signInLink">sign in</a>
    to reply
  </div>
</template>
