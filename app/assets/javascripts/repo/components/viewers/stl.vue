<script>
  import { mapGetters } from 'vuex';
  import Renderer from '../../../blob/3d_viewer/index';
  import loadingIcon from '../../../vue_shared/components/loading_icon.vue';

  export default {
    components: {
      loadingIcon,
    },
    computed: {
      ...mapGetters([
        'activeFile',
      ])
    },
    mounted() {
      this.$nextTick(() => {
        new Renderer(this.$el, this.$el.offsetHeight);
      });
    },
  }
</script>

<template>
  <div
    :data-endpoint="activeFile.rawPath"
    class="blob-full-height"
  >
    <div class="text-center prepend-top-default append-bottom-default blob-full-width">
      <loading-icon
        class="prepend-top-default append-bottom-default"
        :inline="true"
        size="2"
      />
    </div>
  </div>
</template>
