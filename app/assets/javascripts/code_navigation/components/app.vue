<script>
import { mapActions, mapState } from 'vuex';
import eventHub from '../../notes/event_hub';
import Popover from './popover.vue';

export default {
  components: {
    Popover,
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
    ...mapActions(['fetchData', 'showDefinition', 'showBlobInteractionZones']),
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
