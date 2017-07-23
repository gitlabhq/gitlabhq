export default {
  name: 'MRWidgetPipelineBlocked',
  template: `
    <div class="mr-widget-body">
      <button
        type="button"
        class="btn btn-success btn-small"
        disabled="true">
        Merge
      </button>
      <span class="bold">
        Pipeline blocked. The pipeline for this merge request requires a manual action to proceed.
      </span>
    </div>
  `,
};
