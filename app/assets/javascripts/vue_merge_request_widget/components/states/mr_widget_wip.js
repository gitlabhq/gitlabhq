import mrWidgetMergeHelp from '../../components/mr_widget_merge_help';

export default {
  name: 'MRWidgetWIP',
  props: {
    mr: { type: Object, required: true },
  },
  components: {
    'mr-widget-merge-help': mrWidgetMergeHelp,
  },
  template: `
    <div class="mr-widget-body">
      <button class="btn btn-success btn-small" disabled="disabled">Merge</button>
      <span class="bold">This merge request is currently Work In Progress and therefore unable to merge</span>
      <template v-if="mr.canUpdateMergeRequest">
        <i class="fa fa-question-circle has-tooltip" title="When this merge request is ready, remove the WIP: prefix from the title to allow it to be merged."></i>
        <a :href="mr.removeWIPPath" data-method="post" class="btn btn-default btn-xs">Resolve WIP status</a>
        <mr-widget-merge-help />
      </template>
    </div>
  `,
};
