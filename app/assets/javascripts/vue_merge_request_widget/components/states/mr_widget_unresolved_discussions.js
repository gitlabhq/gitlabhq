export default {
  name: 'MRWidgetUnresolvedDiscussions',
  props: {
    mr: { type: Object, required: true },
  },
  template: `
    <div class="mr-widget-body">
      <button type="button" class="btn btn-success btn-small" disabled="true">Merge</button>
      <span class="bold">
        This merge request has unresolved discussions. Please resolve these discussions allow this merge request to be merged.
      </span>
      <a
        v-if="mr.canCreateIssue"
        :href="mr.createIssueToResolveDiscussionsPath"
        class="btn btn-default btn-xs">Create an issue to resolve them later</a>
    </div>
  `,
};
