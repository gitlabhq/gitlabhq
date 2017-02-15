export default {
  name: 'MRWidgetConflicts',
  props: {
    mr: { type: Object, required: true },
  },
  computed: {
    showResolveConflictsButton() {
      const { canMerge, canResolveConflicts, canResolveConflictsInUI } = this.mr;
      return canMerge && canResolveConflicts && canResolveConflictsInUI;
    },
  },
  template: `
    <div class="mr-widget-body">
      <button type="button" class="btn btn-success btn-small" disabled="true">Merge</button>
      <span class="bold">
        There are merge conflicts.
        <span v-if="!mr.canMerge">Resolve these conflicts or ask someone with write access to this repository to merge it locally.</span>
      </span>
      <div class="btn-group">
        <a
          :href="mr.conflictResolutionPath"
          v-if="showResolveConflictsButton"
          class="btn btn-default btn-xs js-resolve-conflicts-button"
        >Resolve conflicts</a>
        <a
          v-if="mr.canMerge"
          class="btn btn-default btn-xs js-merge-locally-button"
          data-toggle="modal"
          href="#modal_merge_info"
        >Merge locally</a>
      </div>
    </div>
  `,
};
