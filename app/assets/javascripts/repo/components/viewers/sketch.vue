<script>
  import { mapGetters } from 'vuex';
  import Sketch from '../../../blob/sketch';

  export default {
    computed: {
      ...mapGetters([
        'activeFile',
      ]),
    },
    mounted() {
      this.$nextTick(() => {
        new Sketch(this.$el);
      });
    },
  };
</script>

<template>
  <div
    :data-endpoint="activeFile.rawPath"
    class="prepend-top-default append-bottom-default prepend-left-default append-right-default"
  >
  </div>
</template>
