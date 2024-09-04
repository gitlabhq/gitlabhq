<script>
import { union } from 'lodash';
import activeBoardItemQuery from 'ee_else_ce/boards/graphql/client/active_board_item.query.graphql';
import setActiveBoardItemMutation from 'ee_else_ce/boards/graphql/client/set_active_board_item.mutation.graphql';
import { TYPE_ISSUE } from '~/issues/constants';
import { ListType } from 'ee_else_ce/boards/constants';
import { identifyAffectedLists } from '../graphql/cache_updates';

export default {
  name: 'BoardDrawerWrapper',
  inject: {
    issuableType: {
      default: TYPE_ISSUE,
    },
  },
  props: {
    backlogListId: {
      type: String,
      required: true,
    },
    closedListId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      affectedListTypes: [],
      updatedAttributeIds: [],
    };
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    activeBoardItem: {
      query: activeBoardItemQuery,
      variables() {
        return {
          isIssue: this.isIssue,
        };
      },
    },
  },
  computed: {
    apolloClient() {
      return this.$apollo.getClient();
    },
    isIssue() {
      return this.issuableType === TYPE_ISSUE;
    },
    typename() {
      return this.isIssue ? 'BoardList' : 'EpicList';
    },
    issuableListName() {
      return `${this.issuableType}s`;
    },
    metadataFieldName() {
      return this.isIssue ? 'issuesCount' : 'metadata';
    },
  },
  methods: {
    async onDrawerClosed() {
      const item = this.activeBoardItem;

      await this.$apollo.mutate({
        mutation: setActiveBoardItemMutation,
        variables: {
          boardItem: null,
          listId: null,
        },
      });

      if (item.listId !== this.closedListId || this.affectedListTypes.includes(ListType.closed)) {
        await this.refetchAffectedLists(item);
      }
      this.affectedListTypes = [];
      this.updatedAttributeIds = [];
    },
    onAttributeUpdated({ ids, type }) {
      if (!this.affectedListTypes.includes(type)) {
        this.affectedListTypes.push(type);
      }
      this.updatedAttributeIds = union(this.updatedAttributeIds, ids);
    },
    refetchAffectedLists(item) {
      if (!this.affectedListTypes.length) {
        return;
      }

      const affectedLists = identifyAffectedLists({
        client: this.apolloClient,
        item,
        issuableType: this.issuableType,
        affectedListTypes: this.affectedListTypes,
        updatedAttributeIds: this.updatedAttributeIds,
      });

      if (this.backlogListId && !affectedLists.includes(this.backlogListId)) {
        affectedLists.push(this.backlogListId);
      }

      if (this.closedListId && this.affectedListTypes.includes(ListType.closed)) {
        affectedLists.push(this.closedListId);
      }

      this.refetchActiveIssuableLists(item);

      this.apolloClient.refetchQueries({
        updateCache: (cache) => {
          affectedLists.forEach((listId) => {
            cache.evict({
              id: cache.identify({
                __typename: this.typename,
                id: listId,
              }),
              fieldName: this.issuableListName,
            });
            cache.evict({
              id: cache.identify({
                __typename: this.typename,
                id: listId,
              }),
              fieldName: this.metadataFieldName,
            });
          });
        },
      });
    },
    refetchActiveIssuableLists(item) {
      this.apolloClient.refetchQueries({
        updateCache(cache) {
          cache.evict({ id: cache.identify(item) });
        },
      });
    },
    onStateUpdated() {
      this.affectedListTypes.push(ListType.closed);
    },
  },
  render() {
    return this.$scopedSlots.default({
      activeIssuable: this.activeBoardItem,
      onDrawerClosed: this.onDrawerClosed,
      onAttributeUpdated: this.onAttributeUpdated,
      onIssuableDeleted: this.refetchActiveIssuableLists,
      onStateUpdated: this.onStateUpdated,
    });
  },
};
</script>
