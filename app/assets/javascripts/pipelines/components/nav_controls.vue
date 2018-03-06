<script>
  export default {
    name: 'PipelineNavControls',
    props: {
      newPipelinePath: {
        type: String,
        required: false,
        default: null,
      },

      resetCachePath: {
        type: String,
        required: false,
        default: null,
      },

      ciLintPath: {
        type: String,
        required: false,
        default: null,
      },
    },
  };
</script>
<template>
  <div class="nav-controls">
    <a
      v-if="newPipelinePath"
      :href="newPipelinePath"
      class="btn btn-create js-run-pipeline"
    >
      {{ s__('Pipelines|Run Pipeline') }}
    </a>

    <a
      v-if="resetCachePath"
      data-method="post"
      :href="resetCachePath"
      class="btn btn-default js-clear-cache"
    >
      {{ s__('Pipelines|Clear Runner Caches') }}
    </a>

    <a
      v-if="ciLintPath"
      :href="ciLintPath"
      class="btn btn-default js-ci-lint"
    >
      {{ s__('Pipelines|CI Lint') }}
    </a>
  </div>
</template>
