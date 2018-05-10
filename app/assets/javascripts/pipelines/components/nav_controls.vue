<script>
  import LoadingButton from '../../vue_shared/components/loading_button.vue';

  export default {
    name: 'PipelineNavControls',
    components: {
      LoadingButton,
    },
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

      isResetCacheButtonLoading: {
        type: Boolean,
        required: false,
        default: false,
      },
    },
    methods: {
      onClickResetCache() {
        this.$emit('resetRunnersCache', this.resetCachePath);
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

    <loading-button
      v-if="resetCachePath"
      @click="onClickResetCache"
      :loading="isResetCacheButtonLoading"
      class="btn btn-default js-clear-cache"
      :label="s__('Pipelines|Clear Runner Caches')"
    />

    <a
      v-if="ciLintPath"
      :href="ciLintPath"
      class="btn btn-default js-ci-lint"
    >
      {{ s__('Pipelines|CI Lint') }}
    </a>
  </div>
</template>
