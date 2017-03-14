import mrWidgetMergeHelp from '../../components/mr_widget_merge_help';

export default {
  name: 'MRWidgetNothingToMerge',
  components: {
    'mr-widget-merge-help': mrWidgetMergeHelp,
  },
  template: `
    <div class="mr-widget-body">
      <button class="btn btn-success btn-small" disabled="true">Merge</button>
      <span class="bold">
        There is nothing to merge from source branch into target branch.
        Please push new commits or use a different branch.
      </span>
      <mr-widget-merge-help />
    </div>
  `,
};
