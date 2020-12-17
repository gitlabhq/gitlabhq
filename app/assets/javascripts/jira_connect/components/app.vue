<script>
export default {
  name: 'JiraConnectApp',
  computed: {
    state() {
      return this.$root.$data.state || {};
    },
    error() {
      return this.state.error;
    },
  },
};
</script>
<template>
  <div></div>
</template>
