<script>
import _ from 'underscore';
import StageColumnComponent from './stage_column_component.vue';
import LinkedPipelinesColumn from 'ee/pipelines/components/graph/linked_pipelines_column.vue'; // eslint-disable-line import/first

export default {
  components: {
    LinkedPipelinesColumn,
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
    triggered() {
      return this.pipeline.triggered || [];
    },
    triggeredBy() {
      const response = this.pipeline.triggered_by;
      return response ? [response] : [];
    },
    hasTriggered() {
      return !!this.triggered.length;
    },
    hasTriggeredBy() {
      return !!this.triggeredBy.length;
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

      <linked-pipelines-column
        v-if="hasTriggeredBy"
        :linked-pipelines="triggeredBy"
        column-title="Upstream"
        graph-position="left"
      />

      <ul
        v-if="!isLoading"
        :class="{
          'has-linked-pipelines': hasTriggered || hasTriggeredBy
        }"
        class="stage-column-list"
      >
        <stage-column-component
          v-for="(stage, index) in graph"
          :class="{
            'has-upstream': index === 0 && hasTriggeredBy,
            'has-downstream': index === graph.length - 1 && hasTriggered,
            'has-only-one-job': stage.groups.length === 1
          }"
          :title="capitalizeStageName(stage.name)"
          :jobs="stage.groups"
          :key="stage.name"
          :stage-connector-class="stageConnectorClass(index, stage)"
          :is-first-column="isFirstColumn(index)"
          :has-triggered-by="hasTriggeredBy"
          @refreshPipelineGraph="refreshPipelineGraph"
        />
      </ul>

      <linked-pipelines-column
        v-if="hasTriggered"
        :linked-pipelines="triggered"
        column-title="Downstream"
        graph-position="right"
      />
    </div>
  </div>
</template>
