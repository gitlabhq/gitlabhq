<script>
  export default {
    data() {
      return {
        signInLink: '#',
      };
    },
    mounted() {
      const wrapper = document.querySelector('.js-notes-wrapper');

      if (wrapper) {
        this.signInLink = wrapper.dataset.newSessionPath;
      }
    },
  };
</script>

<template>
  <div class="disabled-comment text-center">
    Please
    <a :href="signInLink">register</a>
    or
    <a :href="signInLink">sign in</a>
    to reply
  </div>
</template>
