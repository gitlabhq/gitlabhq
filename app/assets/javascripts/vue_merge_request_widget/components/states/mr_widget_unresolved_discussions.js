export default {
  name: 'MRWidgetUnresolvedDiscussions',
  props: {
    mr: { type: Object, required: true },
  },
  template: `
    <div class="mr-widget-body">
      <button
        type="button"
        class="btn btn-success btn-small"
        disabled="true">
        Merge
      </button>
      <span class="bold">
        There are unresolved discussions. Please resolve these discussions
        <span v-if="mr.canCreateIssue">or</span>
        <span v-else>.</span>
      </span>
      <a
        v-if="mr.createIssueToResolveDiscussionsPath"
        :href="mr.createIssueToResolveDiscussionsPath"
        class="btn btn-default btn-xs js-create-issue">
        Create an issue to resolve them later
      </a>
    </div>
  `,
};
