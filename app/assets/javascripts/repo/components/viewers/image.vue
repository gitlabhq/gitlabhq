<script>
  import { mapGetters } from 'vuex';

  export default {
    computed: {
      ...mapGetters([
        'activeFile',
      ]),
    },
  };
</script>

<template>
  <div class="text-center prepend-top-default append-bottom-default">
    <img
      :src="activeFile.rawPath"
    />
  </div>
</template>
