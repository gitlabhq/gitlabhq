/* global Flash */

export default {
  name: 'MRWidgetWIP',
  props: {
    mr: { type: Object, required: true },
    service: { type: Object, required: true },
  },
  methods: {
    removeWIP() {
      this.service.removeWIP()
        .then(res => res.json())
        .then((res) => {
          // TODO: Update store better
          this.mr.setData(res);
          new Flash('The merge request can now be merged.', 'notice'); // eslint-disable-line
          $('.merge-request .detail-page-description .title').text(this.mr.title);
        });
        // TODO: Catch error state
    },
  },
  template: `
    <div class="mr-widget-body">
      <button type="button" class="btn btn-success btn-small" disabled="true">Merge</button>
      <span class="bold">This merge request is currently Work In Progress and therefore unable to merge</span>
      <template v-if="mr.canUpdateMergeRequest">
        <i class="fa fa-question-circle has-tooltip" title="When this merge request is ready, remove the WIP: prefix from the title to allow it to be merged."></i>
        <button
          @click="removeWIP"
          type="button" class="btn btn-default btn-xs">Resolve WIP status</button>
      </template>
    </div>
  `,
};
