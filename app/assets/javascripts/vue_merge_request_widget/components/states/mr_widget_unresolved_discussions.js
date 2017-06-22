export default {
  name: 'MRWidgetUnresolvedDiscussions',
  props: {
    mr: { type: Object, required: true },
  },
  computed: {
    text() {
      const sep = this.mr.createIssueToResolveDiscussionsPath ? ' or' : '.';
      return `There are unresolved discussions. Please resolve these discussions${sep}`;
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
      <strong>
        {{text}}
      </strong>
      <a
        v-if="mr.createIssueToResolveDiscussionsPath"
        :href="mr.createIssueToResolveDiscussionsPath"
        class="btn btn-default btn-xs js-create-issue">
        Create an issue to resolve them later
      </a>
    </div>
  `,
};
