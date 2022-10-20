<script>
import {
  GlAlert,
  GlFormGroup,
  GlDropdown,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlSearchBoxByType,
  GlIntersectionObserver,
  GlLoadingIcon,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import { s__, __ } from '~/locale';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import currentUserNamespace from '~/projects/settings/graphql/queries/current_user_namespace.query.graphql';

export const i18n = {
  SELECT_A_NAMESPACE: __('Select a new namespace'),
  GROUPS: __('Groups'),
  USERS: __('Users'),
  ERROR_MESSAGE: s__(
    'ProjectTransfer|An error occurred fetching the transfer locations, please refresh the page and try again.',
  ),
  ALERT_DISMISS_LABEL: __('Dismiss'),
};

export default {
  name: 'TransferLocations',
  components: {
    GlAlert,
    GlFormGroup,
    GlDropdown,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlSearchBoxByType,
    GlIntersectionObserver,
    GlLoadingIcon,
  },
  inject: ['resourceId'],
  props: {
    value: {
      type: Object,
      required: false,
      default: null,
    },
    groupTransferLocationsApiMethod: {
      type: Function,
      required: true,
    },
  },
  initialTransferLocationsLoaded: false,
  data() {
    return {
      searchTerm: '',
      userTransferLocations: [],
      groupTransferLocations: [],
      isLoading: false,
      isSearchLoading: false,
      hasError: false,
      page: 1,
      totalPages: 1,
    };
  },
  computed: {
    hasUserTransferLocations() {
      return this.userTransferLocations.length;
    },
    hasGroupTransferLocations() {
      return this.groupTransferLocations.length;
    },
    selectedText() {
      return this.value?.humanName || i18n.SELECT_A_NAMESPACE;
    },
    hasNextPageOfGroups() {
      return this.page < this.totalPages;
    },
  },
  watch: {
    searchTerm() {
      this.page = 1;

      this.debouncedSearch();
    },
  },
  methods: {
    handleSelect(item) {
      this.searchTerm = '';
      this.$emit('input', item);
    },
    async handleShow() {
      if (this.$options.initialTransferLocationsLoaded) {
        return;
      }

      this.isLoading = true;

      [this.groupTransferLocations, this.userTransferLocations] = await Promise.all([
        this.getGroupTransferLocations(),
        this.getUserTransferLocations(),
      ]);

      this.isLoading = false;
      this.$options.initialTransferLocationsLoaded = true;
    },
    async getGroupTransferLocations() {
      try {
        const {
          data: groupTransferLocations,
          headers,
        } = await this.groupTransferLocationsApiMethod(this.resourceId, {
          page: this.page,
          search: this.searchTerm,
        });

        const { totalPages } = parseIntPagination(normalizeHeaders(headers));
        this.totalPages = totalPages;

        return groupTransferLocations.map(({ id, full_name: humanName }) => ({
          id,
          humanName,
        }));
      } catch {
        this.handleError();

        return [];
      }
    },
    async getUserTransferLocations() {
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
      } catch {
        this.handleError();

        return [];
      }
    },
    async handleLoadMoreGroups() {
      this.isLoading = true;
      this.page += 1;

      const groupTransferLocations = await this.getGroupTransferLocations();
      this.groupTransferLocations.push(...groupTransferLocations);

      this.isLoading = false;
    },
    debouncedSearch: debounce(async function debouncedSearch() {
      this.isSearchLoading = true;

      this.groupTransferLocations = await this.getGroupTransferLocations();

      this.isSearchLoading = false;
    }, DEBOUNCE_DELAY),
    handleError() {
      this.hasError = true;
    },
    handleAlertDismiss() {
      this.hasError = false;
    },
  },
  i18n,
};
</script>
<template>
  <div>
    <gl-alert
      v-if="hasError"
      variant="danger"
      :dismiss-label="$options.i18n.ALERT_DISMISS_LABEL"
      @dismiss="handleAlertDismiss"
      >{{ $options.i18n.ERROR_MESSAGE }}</gl-alert
    >
    <gl-form-group :label="$options.i18n.SELECT_A_NAMESPACE">
      <gl-dropdown :text="selectedText" data-qa-selector="namespaces_list" block @show="handleShow">
        <template #header>
          <gl-search-box-by-type
            v-model.trim="searchTerm"
            :is-loading="isSearchLoading"
            data-qa-selector="namespaces_list_search"
          />
        </template>
        <div
          v-if="hasUserTransferLocations"
          data-qa-selector="namespaces_list_users"
          data-testid="user-transfer-locations"
        >
          <gl-dropdown-section-header>{{ $options.i18n.USERS }}</gl-dropdown-section-header>
          <gl-dropdown-item
            v-for="item in userTransferLocations"
            :key="item.id"
            data-qa-selector="namespaces_list_item"
            @click="handleSelect(item)"
            >{{ item.humanName }}</gl-dropdown-item
          >
        </div>
        <div
          v-if="hasGroupTransferLocations"
          data-qa-selector="namespaces_list_groups"
          data-testid="group-transfer-locations"
        >
          <gl-dropdown-section-header>{{ $options.i18n.GROUPS }}</gl-dropdown-section-header>
          <gl-dropdown-item
            v-for="item in groupTransferLocations"
            :key="item.id"
            data-qa-selector="namespaces_list_item"
            @click="handleSelect(item)"
            >{{ item.humanName }}</gl-dropdown-item
          >
        </div>
        <gl-loading-icon v-if="isLoading" class="gl-mb-3" size="sm" />
        <gl-intersection-observer v-if="hasNextPageOfGroups" @appear="handleLoadMoreGroups" />
      </gl-dropdown>
    </gl-form-group>
  </div>
</template>
