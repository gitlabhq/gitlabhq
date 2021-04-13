<script>
import actionCable from '~/actioncable_consumer';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { assigneesQueries } from '~/sidebar/constants';

export default {
  subscription: null,
  name: 'AssigneesRealtime',
  props: {
    mediator: {
      type: Object,
      required: false,
      default: null,
    },
    issuableIid: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    issuableType: {
      type: String,
      required: true,
    },
  },
  apollo: {
    workspace: {
      query() {
        return assigneesQueries[this.issuableType].query;
      },
      variables() {
        return {
          iid: this.issuableIid,
          fullPath: this.projectPath,
        };
      },
      result(data) {
        if (this.mediator) {
          this.handleFetchResult(data);
        }
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
        this.$apollo.queries.workspace.refetch();
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
      const { nodes } = data.workspace.issuable.assignees;

      const assignees = nodes.map((n) => ({
        ...n,
        avatar_url: n.avatarUrl,
        id: getIdFromGraphQLId(n.id),
      }));

      this.mediator.store.setAssigneesFromRealtime(assignees);
    },
  },
  render() {
    return null;
  },
};
</script>
