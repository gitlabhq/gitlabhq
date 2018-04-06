<script>
import LoadingIcon from '~/vue_shared/components/loading_icon.vue';
import StageColumnComponent from './stage_column_component.vue';
<<<<<<< HEAD
import LinkedPipelinesColumn from 'ee/pipelines/components/graph/linked_pipelines_column.vue'; // eslint-disable-line import/first

export default {
  components: {
    LinkedPipelinesColumn,
    StageColumnComponent,
    LoadingIcon,
  },
=======

export default {
  components: {
    StageColumnComponent,
    LoadingIcon,
  },

>>>>>>> upstream/master
  props: {
    isLoading: {
      type: Boolean,
      required: true,
    },
    pipeline: {
      type: Object,
      required: true,
    },
    actionDisabled: {
      type: String,
      required: false,
      default: null,
    },
  },

  computed: {
    graph() {
      return this.pipeline.details && this.pipeline.details.stages;
<<<<<<< HEAD
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
=======
    },
>>>>>>> upstream/master
  },

  methods: {
    capitalizeStageName(name) {
      return name.charAt(0).toUpperCase() + name.slice(1);
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
  },
};
</script>
<template>
  <div class="build-content middle-block js-pipeline-graph">
    <div class="pipeline-visualization pipeline-graph pipeline-tab-content">
      <div class="text-center">
        <loading-icon
          v-if="isLoading"
          size="3"
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
        class="stage-column-list"
        :class="{
          'has-linked-pipelines': hasTriggered || hasTriggeredBy
        }"
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
          :action-disabled="actionDisabled"
<<<<<<< HEAD
          :has-triggered-by="hasTriggeredBy"
=======
>>>>>>> upstream/master
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
