const mrWidgetMergeHelp = require('../../components/mr_widget_merge_help.js');

module.exports = {
  name: 'MRWidgetWIP',
  props: {
    mr: { type: Object, required: true, default: () => ({}) }
  },
  components: {
    'mr-widget-merge-help': mrWidgetMergeHelp
  },
  template: `
    <div class="mr-widget-body">
      <button class="btn btn-success btn-small" disabled="disabled">Merge</button>
      <span class="bold">This is currently Work In Progress and therefore unable to merge</span>
      <i class="fa fa-question-circle"></i>
      <button class="btn btn-default btn-xs">Resolve WIP status</button>
      <mr-widget-merge-help />
    </div>
  `
}
