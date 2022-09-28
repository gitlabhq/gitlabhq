<script>
import { GlFormGroup, GlAlert } from '@gitlab/ui';
import { debounce } from 'lodash';
import ConfirmDanger from '~/vue_shared/components/confirm_danger/confirm_danger.vue';
import NamespaceSelect from '~/vue_shared/components/namespace_select/namespace_select.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { getTransferLocations } from '~/api/projects_api';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import { s__, __ } from '~/locale';
import currentUserNamespace from '../graphql/queries/current_user_namespace.query.graphql';

export default {
  name: 'TransferProjectForm',
  components: {
    GlFormGroup,
    NamespaceSelect,
    ConfirmDanger,
    GlAlert,
  },
  i18n: {
    errorMessage: s__(
      'ProjectTransfer|An error occurred fetching the transfer locations, please refresh the page and try again.',
    ),
    alertDismissAlert: __('Dismiss'),
  },
  inject: ['projectId'],
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
  data() {
    return {
      userNamespaces: [],
      groupNamespaces: [],
      initialNamespacesLoaded: false,
      selectedNamespace: null,
      hasError: false,
      isLoading: false,
      isSearchLoading: false,
      searchTerm: '',
      page: 1,
      totalPages: 1,
    };
  },
  computed: {
    hasSelectedNamespace() {
      return Boolean(this.selectedNamespace?.id);
    },
    hasNextPageOfGroups() {
      return this.page < this.totalPages;
    },
  },
  methods: {
    async handleShow() {
      if (this.initialNamespacesLoaded) {
        return;
      }

      this.isLoading = true;

      [this.groupNamespaces, this.userNamespaces] = await Promise.all([
        this.getGroupNamespaces(),
        this.getUserNamespaces(),
      ]);

      this.isLoading = false;
      this.initialNamespacesLoaded = true;
    },
    handleSelect(selectedNamespace) {
      this.selectedNamespace = selectedNamespace;
      this.$emit('selectNamespace', selectedNamespace.id);
    },
    async getGroupNamespaces() {
      try {
        const { data: groupNamespaces, headers } = await getTransferLocations(this.projectId, {
          page: this.page,
          search: this.searchTerm,
        });

        const { totalPages } = parseIntPagination(normalizeHeaders(headers));
        this.totalPages = totalPages;

        return groupNamespaces.map(({ id, full_name: humanName }) => ({
          id,
          humanName,
        }));
      } catch (error) {
        this.hasError = true;

        return [];
      }
    },
    async getUserNamespaces() {
      try {
        const {
          data: {
            currentUser: { namespace },
          },
        } = await this.$apollo.query({
          query: currentUserNamespace,
        });

        if (!namespace) {
          return [];
        }

        return [
          {
            id: getIdFromGraphQLId(namespace.id),
            humanName: namespace.fullName,
          },
        ];
      } catch (error) {
        this.hasError = true;

        return [];
      }
    },
    async handleLoadMoreGroups() {
      this.isLoading = true;
      this.page += 1;

      const groupNamespaces = await this.getGroupNamespaces();
      this.groupNamespaces.push(...groupNamespaces);

      this.isLoading = false;
    },
    debouncedSearch: debounce(async function debouncedSearch() {
      this.isSearchLoading = true;

      this.groupNamespaces = await this.getGroupNamespaces();

      this.isSearchLoading = false;
    }, DEBOUNCE_DELAY),
    handleSearch(searchTerm) {
      this.searchTerm = searchTerm;
      this.page = 1;

      this.debouncedSearch();
    },
    handleAlertDismiss() {
      this.hasError = false;
    },
  },
};
</script>
<template>
  <div>
    <gl-alert
      v-if="hasError"
      variant="danger"
      :dismiss-label="$options.i18n.alertDismissLabel"
      @dismiss="handleAlertDismiss"
      >{{ $options.i18n.errorMessage }}</gl-alert
    >
    <gl-form-group>
      <namespace-select
        data-testid="transfer-project-namespace"
        :full-width="true"
        :group-namespaces="groupNamespaces"
        :user-namespaces="userNamespaces"
        :selected-namespace="selectedNamespace"
        :has-next-page-of-groups="hasNextPageOfGroups"
        :is-loading="isLoading"
        :is-search-loading="isSearchLoading"
        :should-filter-namespaces="false"
        @select="handleSelect"
        @load-more-groups="handleLoadMoreGroups"
        @search="handleSearch"
        @show="handleShow"
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
