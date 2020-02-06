<script>
import { mapActions, mapState } from 'vuex';
import Popover from './popover.vue';

export default {
  components: {
    Popover,
  },
  computed: {
    ...mapState(['currentDefinition', 'currentDefinitionPosition']),
  },
  mounted() {
    this.blobViewer = document.querySelector('.blob-viewer');

    this.addGlobalEventListeners();
    this.fetchData();
  },
  beforeDestroy() {
    this.removeGlobalEventListeners();
  },
  methods: {
    ...mapActions(['fetchData', 'showDefinition']),
    addGlobalEventListeners() {
      if (this.blobViewer) {
        this.blobViewer.addEventListener('click', this.showDefinition);
      }
    },
    removeGlobalEventListeners() {
      if (this.blobViewer) {
        this.blobViewer.removeEventListener('click', this.showDefinition);
      }
    },
  },
};
</script>

<template>
  <popover
    v-if="currentDefinition"
    :position="currentDefinitionPosition"
    :data="currentDefinition"
  />
</template>
