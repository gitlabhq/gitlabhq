<script>
  import linkedPipeline from './linked_pipeline.vue';

  export default {
    components: {
      linkedPipeline,
    },
    props: {
      columnTitle: {
        type: String,
        required: true,
      },
      linkedPipelines: {
        type: Array,
        required: true,
      },
      graphPosition: {
        type: String,
        required: true,
      },
    },

    computed: {
      columnClass() {
        return `graph-position-${this.graphPosition}`;
      },
    },
  };
</script>

<template>
  <div
    class="stage-column linked-pipelines-column"
    :class="columnClass"
  >
    <div class="stage-name linked-pipelines-column-title"> {{ columnTitle }} </div>
    <div class="cross-project-triangle"></div>
    <ul>
      <linked-pipeline
        v-for="(pipeline, index) in linkedPipelines"
        :class="{
          'flat-connector-before': index === 0 && graphPosition === 'right'
        }"
        :key="pipeline.id"
        :pipeline-id="pipeline.id"
        :project-name="pipeline.project.name"
        :pipeline-status="pipeline.details.status"
        :pipeline-path="pipeline.path"
      />
    </ul>
  </div>
</template>
