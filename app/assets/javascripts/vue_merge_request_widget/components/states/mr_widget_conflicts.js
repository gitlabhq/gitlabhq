import mrWidgetPipeline from '../../components/mr_widget_pipeline';

export default {
  name: 'MRWidgetConflicts',
  props: {
    mr: { type: Object, required: true },
  },
  components: {
    'mr-widget-pipeline': mrWidgetPipeline,
  },
  computed: {
    showResolveConflictsButton() {
      const { canMerge, canResolveConflicts, canResolveConflictsInUI } = this.mr;
      return canMerge && canResolveConflicts && canResolveConflictsInUI;
    },
  },
  template: `
    <div class="mr-widget-wrapper">
      <mr-widget-pipeline v-if="mr.pipeline" :mr="mr" />
      <div class="mr-widget-body">
        <button class="btn btn-success btn-small" disabled="true">Merge</button>
        <span class="bold">
          There are merge conflicts.
          <span v-if="!mr.canMerge">Resolve these conflicts or ask someone with write access to this repository to merge it locally.</span>
        </span>
        <a
          :href="mr.conflictResolutionPath"
          v-if="showResolveConflictsButton"
          class="btn btn-default btn-xs how_to_merge_link vlink"
        >Resolve conflicts</a>
        <a
          v-if="mr.canMerge"
          class="btn btn-default btn-xs how_to_merge_link vlink"
          data-toggle="modal"
          href="#modal_merge_info"
        >Merge locally</a>
      </div>
    </div>
  `,
};
