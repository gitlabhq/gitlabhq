export default {
  name: 'MRWidgetPipelineBlocked',
  template: `
    <div class="mr-widget-body">
      <button
        class="btn btn-success btn-small"
        disabled="true"
        type="button">
        Merge
      </button>
      <span class="bold">
        The pipeline for this merge request failed. Please retry the job or push a new commit to fix the failure.
      </span>
    </div>
  `,
};
