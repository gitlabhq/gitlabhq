<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import eventHub from '~/notes/event_hub';
import Popover from './popover.vue';

export default {
  components: {
    Popover,
  },
  props: {
    codeNavigationPath: {
      type: String,
      required: false,
      default: null,
    },
    blobPath: {
      type: String,
      required: false,
      default: null,
    },
    pathPrefix: {
      type: String,
      required: false,
      default: null,
    },
    wrapTextNodes: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState([
      'currentDefinition',
      'currentDefinitionPosition',
      'currentBlobPath',
      'definitionPathPrefix',
    ]),
  },
  mounted() {
    if (this.codeNavigationPath && this.blobPath && this.pathPrefix) {
      const initialData = {
        blobs: [{ path: this.blobPath, codeNavigationPath: this.codeNavigationPath }],
        definitionPathPrefix: this.pathPrefix,
        wrapTextNodes: this.wrapTextNodes,
      };
      this.setInitialData(initialData);
    }

    this.body = document.body;

    eventHub.$on('showBlobInteractionZones', this.showBlobInteractionZones);

    this.addGlobalEventListeners();
    this.fetchData();
  },
  beforeDestroy() {
    eventHub.$off('showBlobInteractionZones', this.showBlobInteractionZones);
    this.removeGlobalEventListeners();
  },
  methods: {
    ...mapActions(['fetchData', 'showDefinition', 'showBlobInteractionZones', 'setInitialData']),
    addGlobalEventListeners() {
      if (this.body) {
        this.body.addEventListener('click', this.showDefinition);
      }
    },
    removeGlobalEventListeners() {
      if (this.body) {
        this.body.removeEventListener('click', this.showDefinition);
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
    :definition-path-prefix="definitionPathPrefix"
    :blob-path="currentBlobPath"
  />
</template>
