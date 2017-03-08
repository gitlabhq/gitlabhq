import mrWidgetMergeHelp from '../../components/mr_widget_merge_help';

export default {
  name: 'MRWidgetChecking',
  components: {
    'mr-widget-merge-help': mrWidgetMergeHelp,
  },
  template: `
    <div class="mr-widget-body">
      <button class="btn btn-success btn-small" disabled="disabled">Merge</button>
      <span class="bold">
        Checking ability to merge automatically.
        <i class="fa fa-spinner fa-spin" aria-hidden="true"></i>
      </span>
      <mr-widget-merge-help />
    </div>
  `,
};
