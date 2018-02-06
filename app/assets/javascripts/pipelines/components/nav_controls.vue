<script>
export default {
  name: 'PipelineNavControls',
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

    resetCachePath: {
      type: String,
      required: true,
    },

    ciLintPath: {
      type: String,
      required: true,
    },

    canCreatePipeline: {
      type: Boolean,
      required: true,
    },
  },
};
</script>
<template>
  <div class="nav-controls">
    <a
      v-if="canCreatePipeline"
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

    <a
      data-method="post"
      rel="nofollow"
      :href="resetCachePath"
      class="btn btn-default">
      Clear runner caches
    </a>

    <a
      :href="ciLintPath"
      class="btn btn-default">
      CI Lint
    </a>
  </div>
</template>
