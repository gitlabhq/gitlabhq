import mrWidgetMergeHelp from '../../components/mr_widget_merge_help';

export default {
  name: 'MRWidgetMissingBranch',
  props: {
    mr: { type: Object, required: true },
  },
  components: {
    'mr-widget-merge-help': mrWidgetMergeHelp,
  },
  computed: {
    missingBranchName() {
      return this.mr.sourceBranchRemoved ? 'source' : 'target';
    },
  },
  template: `
    <div class="mr-widget-body">
      <button
        type="button"
        class="btn btn-success btn-small"
        disabled="true">
        Merge
      </button>
      <span class="bold js-branch-text">
        <span class="capitalize">
          {{missingBranchName}}
        </span> branch does not exist.
        Please restore the {{missingBranchName}} branch or use a different {{missingBranchName}} branch.
      </span>
      <mr-widget-merge-help
        :missing-branch="missingBranchName" />
    </div>
  `,
};
