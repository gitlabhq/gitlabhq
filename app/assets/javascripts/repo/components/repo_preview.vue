<script>
import { mapGetters } from 'vuex';
import flash from '../../flash';
import loadingIcon from '../../vue_shared/components/loading_icon.vue';

export default {
  components: {
    loadingIcon,
  },
  data() {
    return {
      previewComponent: null,
    };
  },
  computed: {
    ...mapGetters([
      'viewerTemplateName',
    ]),
  },
  watch: {
    viewerTemplateName() {
      this.loadComponent();
    },
  },
  methods: {
    loadComponent() {
      this.previewComponent = null;

      import(`./viewers/${this.viewerTemplateName}.vue`)
        .then((comp) => {
          this.previewComponent = comp;
        })
        .catch(() => flash('Error loading file viewer.'));
    },
  },
  mounted() {
    this.loadComponent();
  },
};
</script>

<template>
  <div class="blob-viewer-container">
    <component
      v-if="previewComponent"
      :is="previewComponent"
    />
    <loading-icon
      v-else
      class="prepend-top-default"
      size="2"
    />
  </div>
</template>
