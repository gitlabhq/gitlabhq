<script>
import produce from 'immer';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { IssuableType } from '~/issue_show/constants';
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
    issuableType: {
      type: String,
      required: true,
    },
    issuableId: {
      type: Number,
      required: true,
    },
    queryVariables: {
      type: Object,
      required: true,
    },
  },
  computed: {
    issuableClass() {
      return Object.keys(IssuableType).find((key) => IssuableType[key] === this.issuableType);
    },
  },
  apollo: {
    issuable: {
      query() {
        return assigneesQueries[this.issuableType].query;
      },
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.workspace?.issuable;
      },
      subscribeToMore: {
        document() {
          return assigneesQueries[this.issuableType].subscription;
        },
        variables() {
          return {
            issuableId: convertToGraphQLId(this.issuableClass, this.issuableId),
          };
        },
        updateQuery(prev, { subscriptionData }) {
          if (prev && subscriptionData?.data?.issuableAssigneesUpdated) {
            const data = produce(prev, (draftData) => {
              draftData.workspace.issuable.assignees.nodes =
                subscriptionData.data.issuableAssigneesUpdated.assignees.nodes;
            });
            if (this.mediator) {
              this.handleFetchResult(data);
            }
            return data;
          }
          return prev;
        },
      },
    },
  },
  methods: {
    handleFetchResult(data) {
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
