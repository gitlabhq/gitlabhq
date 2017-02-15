export default {
  name: 'MRWidgetNothingToMerge',
  template: `
    <div class="mr-widget-body">
      <button
        type="button"
        class="btn btn-success btn-small"
        disabled="true">
        Merge
      </button>
      <span class="bold">
        There is nothing to merge from source branch into target branch.
        Please push new commits or use a different branch.
      </span>
    </div>
  `,
};
