<script>
import { GlFormGroup } from '@gitlab/ui';
import produce from 'immer';
import ConfirmDanger from '~/vue_shared/components/confirm_danger/confirm_danger.vue';
import NamespaceSelect from '~/vue_shared/components/namespace_select/namespace_select.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import searchNamespacesWhereUserCanTransferProjects from '../graphql/queries/search_namespaces_where_user_can_transfer_projects.query.graphql';

const GROUPS_PER_PAGE = 25;

export default {
  name: 'TransferProjectForm',
  components: {
    GlFormGroup,
    NamespaceSelect,
    ConfirmDanger,
  },
  props: {
    confirmationPhrase: {
      type: String,
      required: true,
    },
    confirmButtonText: {
      type: String,
      required: true,
    },
  },
  apollo: {
    currentUser: {
      query: searchNamespacesWhereUserCanTransferProjects,
      debounce: DEBOUNCE_DELAY,
      variables() {
        return {
          search: this.searchTerm,
          after: null,
          first: GROUPS_PER_PAGE,
        };
      },
      result() {
        this.isLoadingMoreGroups = false;
        this.isSearchLoading = false;
      },
    },
  },
  data() {
    return {
      currentUser: {},
      selectedNamespace: null,
      isLoadingMoreGroups: false,
      isSearchLoading: false,
      searchTerm: '',
    };
  },
  computed: {
    hasSelectedNamespace() {
      return Boolean(this.selectedNamespace?.id);
    },
    groupNamespaces() {
      return this.currentUser.groups?.nodes?.map(this.formatNamespace) || [];
    },
    userNamespaces() {
      const { namespace } = this.currentUser;

      return namespace ? [this.formatNamespace(namespace)] : [];
    },
    hasNextPageOfGroups() {
      return this.currentUser.groups?.pageInfo?.hasNextPage || false;
    },
  },
  methods: {
    handleSelect(selectedNamespace) {
      this.selectedNamespace = selectedNamespace;
      this.$emit('selectNamespace', selectedNamespace.id);
    },
    handleLoadMoreGroups() {
      this.isLoadingMoreGroups = true;

      this.$apollo.queries.currentUser.fetchMore({
        variables: {
          after: this.currentUser.groups.pageInfo.endCursor,
          first: GROUPS_PER_PAGE,
        },
        updateQuery(
          previousResult,
          {
            fetchMoreResult: {
              currentUser: { groups: newGroups },
            },
          },
        ) {
          const previousGroups = previousResult.currentUser.groups;

          return produce(previousResult, (draftData) => {
            draftData.currentUser.groups.nodes = [...previousGroups.nodes, ...newGroups.nodes];
            draftData.currentUser.groups.pageInfo = newGroups.pageInfo;
          });
        },
      });
    },
    handleSearch(searchTerm) {
      this.isSearchLoading = true;
      this.searchTerm = searchTerm;
    },
    formatNamespace({ id, fullName }) {
      return {
        id: getIdFromGraphQLId(id),
        humanName: fullName,
      };
    },
  },
};
</script>
<template>
  <div>
    <gl-form-group>
      <namespace-select
        data-testid="transfer-project-namespace"
        :full-width="true"
        :group-namespaces="groupNamespaces"
        :user-namespaces="userNamespaces"
        :selected-namespace="selectedNamespace"
        :has-next-page-of-groups="hasNextPageOfGroups"
        :is-loading-more-groups="isLoadingMoreGroups"
        :is-search-loading="isSearchLoading"
        :should-filter-namespaces="false"
        @select="handleSelect"
        @load-more-groups="handleLoadMoreGroups"
        @search="handleSearch"
      />
    </gl-form-group>
    <confirm-danger
      :disabled="!hasSelectedNamespace"
      :phrase="confirmationPhrase"
      :button-text="confirmButtonText"
      @confirm="$emit('confirm')"
    />
  </div>
</template>
