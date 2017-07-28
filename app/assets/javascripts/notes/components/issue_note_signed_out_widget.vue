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
    <a :href="signInLink">register</a>
    or
    <a :href="registerLink">sign in</a>
    to reply
  </div>
</template>
