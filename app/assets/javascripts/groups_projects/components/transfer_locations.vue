<script>
import {
  GlAlert,
  GlFormGroup,
  GlDropdown,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlDropdownDivider,
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
  NO_RESULTS_TEXT: __('No results found.'),
};

export default {
  name: 'TransferLocations',
  components: {
    GlAlert,
    GlFormGroup,
    GlDropdown,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlDropdownDivider,
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
    showUserTransferLocations: {
      type: Boolean,
      required: false,
      default: true,
    },
    additionalDropdownItems: {
      type: Array,
      required: false,
      default() {
        return [];
      },
    },
    label: {
      type: String,
      required: false,
      default: i18n.SELECT_A_NAMESPACE,
    },
  },
  data() {
    return {
      searchTerm: '',
      userTransferLocations: [],
      groupTransferLocations: [],
      filteredAdditionalDropdownItems: this.additionalDropdownItems,
      isLoading: false,
      isSearchLoading: false,
      hasError: false,
      page: 1,
      totalPages: 1,
      initialTransferLocationsLoaded: false,
    };
  },
  computed: {
    hasUserTransferLocations() {
      return this.userTransferLocations.length;
    },
    hasGroupTransferLocations() {
      return this.groupTransferLocations.length;
    },
    hasAdditionalDropdownItems() {
      return this.filteredAdditionalDropdownItems.length;
    },
    selectedText() {
      return this.value?.humanName || this.label;
    },
    hasNextPageOfGroups() {
      return this.page < this.totalPages;
    },
    showAdditionalDropdownItems() {
      return !this.isLoading && this.filteredAdditionalDropdownItems.length;
    },
    hasNoResults() {
      if (this.isLoading || this.isSearchLoading) {
        return false;
      }

      return (
        !this.hasAdditionalDropdownItems &&
        !this.hasUserTransferLocations &&
        !this.hasGroupTransferLocations
      );
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
      if (this.initialTransferLocationsLoaded) {
        return;
      }

      this.isLoading = true;

      [this.groupTransferLocations, this.userTransferLocations] = await Promise.all([
        this.getGroupTransferLocations(),
        this.getUserTransferLocations(),
      ]);

      this.isLoading = false;
      this.initialTransferLocationsLoaded = true;
    },
    async getGroupTransferLocations() {
      try {
        const { data: groupTransferLocations, headers } =
          await this.groupTransferLocationsApiMethod(this.resourceId, {
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
      if (!this.showUserTransferLocations) {
        return [];
      }

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

      this.filteredAdditionalDropdownItems = this.additionalDropdownItems.filter((dropdownItem) =>
        dropdownItem.humanName.toLowerCase().includes(this.searchTerm.toLowerCase()),
      );

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
    <gl-form-group :label="label">
      <gl-dropdown
        :text="selectedText"
        data-testid="transfer-locations-dropdown"
        block
        toggle-class="gl-mb-0"
        class="gl-form-input-xl"
        @show="handleShow"
      >
        <template #header>
          <gl-search-box-by-type
            v-model.trim="searchTerm"
            :is-loading="isSearchLoading"
            data-testid="transfer-locations-search"
            @keydown.enter.prevent
          />
        </template>
        <template v-if="showAdditionalDropdownItems">
          <gl-dropdown-item
            v-for="item in filteredAdditionalDropdownItems"
            :key="item.id"
            @click="handleSelect(item)"
            >{{ item.humanName }}</gl-dropdown-item
          >
          <gl-dropdown-divider />
        </template>
        <div v-if="hasUserTransferLocations" data-testid="user-transfer-locations">
          <gl-dropdown-section-header>{{ $options.i18n.USERS }}</gl-dropdown-section-header>
          <gl-dropdown-item
            v-for="item in userTransferLocations"
            :key="item.id"
            @click="handleSelect(item)"
            >{{ item.humanName }}</gl-dropdown-item
          >
        </div>
        <div v-if="hasGroupTransferLocations" data-testid="group-transfer-locations">
          <gl-dropdown-section-header v-if="showUserTransferLocations">{{
            $options.i18n.GROUPS
          }}</gl-dropdown-section-header>
          <gl-dropdown-item
            v-for="item in groupTransferLocations"
            :key="item.id"
            data-testid="group-transfer-item"
            @click="handleSelect(item)"
            >{{ item.humanName }}</gl-dropdown-item
          >
        </div>
        <gl-dropdown-item v-if="hasNoResults" button-class="!gl-text-default" disabled>{{
          $options.i18n.NO_RESULTS_TEXT
        }}</gl-dropdown-item>
        <gl-loading-icon v-if="isLoading" class="gl-mb-3" size="sm" />
        <gl-intersection-observer v-if="hasNextPageOfGroups" @appear="handleLoadMoreGroups" />
      </gl-dropdown>
    </gl-form-group>
  </div>
</template>
