export default {
  name: 'MRWidgetSHAMismatch',
  template: `
    <div class="mr-widget-body">
      <button
        type="button"
        class="btn btn-success btn-small"
        disabled="true">
        Merge
      </button>
      <span class="bold">
        The source branch HEAD has recently changed. Please reload the page and review the changes before merging.
      </span>
    </div>
  `,
};
