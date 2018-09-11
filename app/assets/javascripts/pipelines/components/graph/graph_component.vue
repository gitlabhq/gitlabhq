<script>
import _ from 'underscore';
import StageColumnComponent from './stage_column_component.vue';

export default {
  components: {
    StageColumnComponent,
  },
  props: {
    isLoading: {
      type: Boolean,
      required: true,
    },
    pipeline: {
      type: Object,
      required: true,
    },
  },

  computed: {
    graph() {
      return this.pipeline.details && this.pipeline.details.stages;
    },
  },

  methods: {
    capitalizeStageName(name) {
      const escapedName = _.escape(name);
      return escapedName.charAt(0).toUpperCase() + escapedName.slice(1);
    },

    isFirstColumn(index) {
      return index === 0;
    },

    stageConnectorClass(index, stage) {
      let className;

      // If it's the first stage column and only has one job
      if (index === 0 && stage.groups.length === 1) {
        className = 'no-margin';
      } else if (index > 0) {
        // If it is not the first column
        className = 'left-margin';
      }

      return className;
    },

    refreshPipelineGraph() {
      this.$emit('refreshPipelineGraph');
    },
  },
};
</script>
<template>
  <div class="build-content middle-block js-pipeline-graph">
    <div class="pipeline-visualization pipeline-graph pipeline-tab-content">
      <div class="text-center">
        <gl-loading-icon
          v-if="isLoading"
          :size="3"
        />
      </div>

      <ul
        v-if="!isLoading"
        class="stage-column-list">
        <stage-column-component
          v-for="(stage, index) in graph"
          :title="capitalizeStageName(stage.name)"
          :jobs="stage.groups"
          :key="stage.name"
          :stage-connector-class="stageConnectorClass(index, stage)"
          :is-first-column="isFirstColumn(index)"
          @refreshPipelineGraph="refreshPipelineGraph"
        />
      </ul>
    </div>
  </div>
</template>
