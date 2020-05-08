<script>
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import query from '~/issuable_sidebar/queries/issue_sidebar.query.graphql';
import actionCable from '~/actioncable_consumer';

export default {
  subscription: null,
  name: 'AssigneesRealtime',
  props: {
    mediator: {
      type: Object,
      required: true,
    },
    issuableIid: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
  },
  apollo: {
    project: {
      query,
      variables() {
        return {
          iid: this.issuableIid,
          fullPath: this.projectPath,
        };
      },
      result(data) {
        this.handleFetchResult(data);
      },
    },
  },
  mounted() {
    this.initActionCablePolling();
  },
  beforeDestroy() {
    this.$options.subscription.unsubscribe();
  },
  methods: {
    received(data) {
      if (data.event === 'updated') {
        this.$apollo.queries.project.refetch();
      }
    },
    initActionCablePolling() {
      this.$options.subscription = actionCable.subscriptions.create(
        {
          channel: 'IssuesChannel',
          project_path: this.projectPath,
          iid: this.issuableIid,
        },
        { received: this.received },
      );
    },
    handleFetchResult({ data }) {
      const { nodes } = data.project.issue.assignees;

      const assignees = nodes.map(n => ({
        ...n,
        avatar_url: n.avatarUrl,
        id: getIdFromGraphQLId(n.id),
      }));

      this.mediator.store.setAssigneesFromRealtime(assignees);
    },
  },
  render() {
    return this.$slots.default;
  },
};
</script>
