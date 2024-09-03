<script>
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { assigneesQueries } from '../../queries/constants';

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
    queryVariables: {
      type: Object,
      required: true,
    },
  },
  computed: {
    issuableId() {
      return this.issuable?.id;
    },
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
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
            issuableId: this.issuableId,
          };
        },
        skip() {
          return !this.issuableId;
        },
        updateQuery(
          _,
          {
            subscriptionData: {
              data: { issuableAssigneesUpdated },
            },
          },
        ) {
          if (issuableAssigneesUpdated) {
            const {
              id,
              assignees: { nodes },
            } = issuableAssigneesUpdated;
            if (this.mediator) {
              this.handleFetchResult(nodes);
            }
            this.$emit('assigneesUpdated', { id, assignees: nodes });
          }
        },
      },
    },
  },
  methods: {
    handleFetchResult(nodes) {
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
