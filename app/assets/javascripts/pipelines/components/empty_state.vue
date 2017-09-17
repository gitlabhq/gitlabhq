<script>
import pipelinesEmptyStateSVG from 'empty_states/icons/_pipelines_empty.svg';

export default {
  props: {
    newPipelinePath: {
      type: String,
      required: true,
    },

    hasCiEnabled: {
      type: Boolean,
      required: true,
    },

    helpPagePath: {
      type: String,
      required: true,
    },

    canCreatePipeline: {
      type: Boolean,
      required: true,
    },
  },
  data: () => ({ pipelinesEmptyStateSVG }),
};
</script>

<template>
  <div class="row empty-state js-empty-state">
    <div class="col-xs-12">
      <div class="svg-content" v-html="pipelinesEmptyStateSVG" />
    </div>

    <div class="col-xs-12 text-center">
      <div
        v-if="canCreatePipeline"
        class="text-content">
        <h4>Build with confidence</h4>
        <p>
          Continuous Integration can help catch bugs by running your tests automatically,
          while Continuous Deployment can help you deliver code to your product environment.
        </p>
        <a
          v-if="hasCiEnabled"
          :href="newPipelinePath"
          class="btn btn-create">
          Run Pipeline
        </a>
        <a
          v-if="!hasCiEnabled"
          :href="helpPagePath"
          class="btn btn-info">
          Get started with Pipelines
        </a>
      </div>

      <div
        v-if="!canCreatePipeline"
        class="text-content">
        <h4>There are no pipelines to show.</h4>
      </div>
    </div>
  </div>
</template>
