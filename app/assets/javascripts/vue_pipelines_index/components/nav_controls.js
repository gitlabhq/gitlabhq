export default {
  props: {
    newPipelinePath: {
      type: String,
      required: true,
    },

    hasCIEnabled: {
      type: Boolean,
      required: true,
    },

    helpPagePath: {
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

  template: `
    <div class="nav-controls">
      <a
        v-if="canCreatePipeline"
        :href="newPipelinePath"
        class="btn btn-create">
        Run Pipeline
      </a>

      <a
        v-if="!hasCIEnabled"
        :href="helpPagePath"
        class="btn btn-info">
        Get started with Pipelines
      </a>

      <a
        :href="ciLintPath"
        class="btn btn-default">
        CI Lint
      </a>
    </div>
  `,
};
