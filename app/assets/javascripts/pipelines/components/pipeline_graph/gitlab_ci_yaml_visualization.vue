<script>
import { GlTab, GlTabs } from '@gitlab/ui';
import jsYaml from 'js-yaml';
import PipelineGraph from './pipeline_graph.vue';
import { preparePipelineGraphData } from '../../utils';

export default {
  FILE_CONTENT_SELECTOR: '#blob-content',
  EMPTY_FILE_SELECTOR: '.nothing-here-block',

  components: {
    GlTab,
    GlTabs,
    PipelineGraph,
  },
  props: {
    blobData: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      selectedTabIndex: 0,
      pipelineData: {},
    };
  },
  computed: {
    isVisualizationTab() {
      return this.selectedTabIndex === 1;
    },
  },
  async created() {
    if (this.blobData) {
      // The blobData in this case represents the gitlab-ci.yml data
      const json = await jsYaml.load(this.blobData);
      this.pipelineData = preparePipelineGraphData(json);
    }
  },
  methods: {
    // This is used because the blob page still uses haml, and we can't make
    // our haml hide the unused section so we resort to a standard query here.
    toggleFileContent({ isFileTab }) {
      const el = document.querySelector(this.$options.FILE_CONTENT_SELECTOR);
      const emptySection = document.querySelector(this.$options.EMPTY_FILE_SELECTOR);

      const elementToHide = el || emptySection;

      if (!elementToHide) {
        return;
      }

      // Checking for the current style display prevents user
      // from toggling visiblity on and off when clicking on the tab
      if (!isFileTab && elementToHide.style.display !== 'none') {
        elementToHide.style.display = 'none';
      }

      if (isFileTab && elementToHide.style.display === 'none') {
        elementToHide.style.display = 'block';
      }
    },
  },
};
</script>
<template>
  <div>
    <div>
      <gl-tabs v-model="selectedTabIndex">
        <gl-tab :title="__('File')" @click="toggleFileContent({ isFileTab: true })" />
        <gl-tab :title="__('Visualization')" @click="toggleFileContent({ isFileTab: false })" />
      </gl-tabs>
    </div>
    <pipeline-graph v-if="isVisualizationTab" :pipeline-data="pipelineData" />
  </div>
</template>
