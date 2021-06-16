<script>
import {
  GlEmptyState,
  GlTooltipDirective,
  GlModal,
  GlSprintf,
  GlLink,
  GlAlert,
  GlSkeletonLoader,
} from '@gitlab/ui';
import { get } from 'lodash';
import getContainerRepositoriesQuery from 'shared_queries/container_registry/get_container_repositories.query.graphql';
import createFlash from '~/flash';
import CleanupPolicyEnabledAlert from '~/packages_and_registries/shared/components/cleanup_policy_enabled_alert.vue';
import { FILTERED_SEARCH_TERM } from '~/packages_and_registries/shared/constants';
import { extractFilterAndSorting } from '~/packages_and_registries/shared/utils';
import Tracking from '~/tracking';
import RegistrySearch from '~/vue_shared/components/registry/registry_search.vue';
import DeleteImage from '../components/delete_image.vue';
import RegistryHeader from '../components/list_page/registry_header.vue';

import {
  DELETE_IMAGE_SUCCESS_MESSAGE,
  DELETE_IMAGE_ERROR_MESSAGE,
  CONNECTION_ERROR_TITLE,
  CONNECTION_ERROR_MESSAGE,
  REMOVE_REPOSITORY_MODAL_TEXT,
  REMOVE_REPOSITORY_LABEL,
  EMPTY_RESULT_TITLE,
  EMPTY_RESULT_MESSAGE,
  GRAPHQL_PAGE_SIZE,
  FETCH_IMAGES_LIST_ERROR_MESSAGE,
  SORT_FIELDS,
} from '../constants/index';
import getContainerRepositoriesDetails from '../graphql/queries/get_container_repositories_details.query.graphql';

export default {
  name: 'RegistryListPage',
  components: {
    GlEmptyState,
    ProjectEmptyState: () =>
      import(
        /* webpackChunkName: 'container_registry_components' */ '../components/list_page/project_empty_state.vue'
      ),
    GroupEmptyState: () =>
      import(
        /* webpackChunkName: 'container_registry_components' */ '../components/list_page/group_empty_state.vue'
      ),
    ImageList: () =>
      import(
        /* webpackChunkName: 'container_registry_components' */ '../components/list_page/image_list.vue'
      ),
    CliCommands: () =>
      import(
        /* webpackChunkName: 'container_registry_components' */ '../components/list_page/cli_commands.vue'
      ),
    GlModal,
    GlSprintf,
    GlLink,
    GlAlert,
    GlSkeletonLoader,
    RegistryHeader,
    DeleteImage,
    RegistrySearch,
    CleanupPolicyEnabledAlert,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin()],
  inject: ['config'],
  loader: {
    repeat: 10,
    width: 1000,
    height: 40,
  },
  i18n: {
    CONNECTION_ERROR_TITLE,
    CONNECTION_ERROR_MESSAGE,
    REMOVE_REPOSITORY_MODAL_TEXT,
    REMOVE_REPOSITORY_LABEL,
    EMPTY_RESULT_TITLE,
    EMPTY_RESULT_MESSAGE,
  },
  searchConfig: SORT_FIELDS,
  apollo: {
    baseImages: {
      skip() {
        return !this.fetchBaseQuery;
      },
      query: getContainerRepositoriesQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data[this.graphqlResource]?.containerRepositories.nodes;
      },
      result({ data }) {
        this.pageInfo = data[this.graphqlResource]?.containerRepositories?.pageInfo;
        this.containerRepositoriesCount = data[this.graphqlResource]?.containerRepositoriesCount;
      },
      error() {
        createFlash({ message: FETCH_IMAGES_LIST_ERROR_MESSAGE });
      },
    },
    additionalDetails: {
      skip() {
        return !this.fetchAdditionalDetails;
      },
      query: getContainerRepositoriesDetails,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data[this.graphqlResource]?.containerRepositories.nodes;
      },
      error() {
        createFlash({ message: FETCH_IMAGES_LIST_ERROR_MESSAGE });
      },
    },
  },
  data() {
    return {
      baseImages: [],
      additionalDetails: [],
      pageInfo: {},
      containerRepositoriesCount: 0,
      itemToDelete: {},
      deleteAlertType: null,
      filter: [],
      sorting: { orderBy: 'UPDATED', sort: 'desc' },
      name: null,
      mutationLoading: false,
      fetchBaseQuery: false,
      fetchAdditionalDetails: false,
    };
  },
  computed: {
    images() {
      if (this.baseImages) {
        return this.baseImages.map((image, index) => ({
          ...image,
          ...get(this.additionalDetails, index, {}),
        }));
      }
      return [];
    },
    graphqlResource() {
      return this.config.isGroupPage ? 'group' : 'project';
    },
    queryVariables() {
      return {
        name: this.name,
        sort: this.sortBy,
        fullPath: this.config.isGroupPage ? this.config.groupPath : this.config.projectPath,
        isGroupPage: this.config.isGroupPage,
        first: GRAPHQL_PAGE_SIZE,
      };
    },
    tracking() {
      return {
        label: 'registry_repository_delete',
      };
    },
    isLoading() {
      return this.$apollo.queries.baseImages.loading || this.mutationLoading;
    },
    showCommands() {
      return Boolean(!this.isLoading && !this.config?.isGroupPage && this.images?.length);
    },
    showDeleteAlert() {
      return this.deleteAlertType && this.itemToDelete?.path;
    },
    deleteImageAlertMessage() {
      return this.deleteAlertType === 'success'
        ? DELETE_IMAGE_SUCCESS_MESSAGE
        : DELETE_IMAGE_ERROR_MESSAGE;
    },
    sortBy() {
      const { orderBy, sort } = this.sorting;
      return `${orderBy}_${sort}`.toUpperCase();
    },
  },
  mounted() {
    const { sorting, filters } = extractFilterAndSorting(this.$route.query);

    this.filter = [...filters];
    this.name = filters[0]?.value.data;
    this.sorting = { ...this.sorting, ...sorting };

    // If the two graphql calls - which are not batched - resolve togheter we will have a race
    //  condition when apollo sets the cache, with this we give the 'base' call an headstart
    this.fetchBaseQuery = true;
    setTimeout(() => {
      this.fetchAdditionalDetails = true;
    }, 200);
  },
  methods: {
    deleteImage(item) {
      this.track('click_button');
      this.itemToDelete = item;
      this.$refs.deleteModal.show();
    },
    dismissDeleteAlert() {
      this.deleteAlertType = null;
      this.itemToDelete = {};
    },
    updateQuery(_, { fetchMoreResult }) {
      return fetchMoreResult;
    },
    async fetchNextPage() {
      if (this.pageInfo?.hasNextPage) {
        const variables = {
          after: this.pageInfo?.endCursor,
          first: GRAPHQL_PAGE_SIZE,
        };

        this.$apollo.queries.baseImages.fetchMore({
          variables,
          updateQuery: this.updateQuery,
        });

        await this.$nextTick();

        this.$apollo.queries.additionalDetails.fetchMore({
          variables,
          updateQuery: this.updateQuery,
        });
      }
    },
    async fetchPreviousPage() {
      if (this.pageInfo?.hasPreviousPage) {
        const variables = {
          first: null,
          before: this.pageInfo?.startCursor,
          last: GRAPHQL_PAGE_SIZE,
        };
        this.$apollo.queries.baseImages.fetchMore({
          variables,
          updateQuery: this.updateQuery,
        });

        await this.$nextTick();

        this.$apollo.queries.additionalDetails.fetchMore({
          variables,
          updateQuery: this.updateQuery,
        });
      }
    },
    startDelete() {
      this.track('confirm_delete');
      this.mutationLoading = true;
    },
    updateSorting(value) {
      this.sorting = {
        ...this.sorting,
        ...value,
      };
    },
    doFilter() {
      const search = this.filter.find((i) => i.type === FILTERED_SEARCH_TERM);
      this.name = search?.value?.data;
    },
    updateUrlQueryString(query) {
      this.$router.push({ query });
    },
  },
};
</script>

<template>
  <div>
    <gl-alert
      v-if="showDeleteAlert"
      :variant="deleteAlertType"
      class="gl-mt-5"
      dismissible
      @dismiss="dismissDeleteAlert"
    >
      <gl-sprintf :message="deleteImageAlertMessage">
        <template #title>
          {{ itemToDelete.path }}
        </template>
      </gl-sprintf>
    </gl-alert>

    <cleanup-policy-enabled-alert
      v-if="config.showCleanupPolicyOnAlert"
      :project-path="config.projectPath"
      :cleanup-policies-settings-path="config.cleanupPoliciesSettingsPath"
    />

    <gl-empty-state
      v-if="config.characterError"
      :title="$options.i18n.CONNECTION_ERROR_TITLE"
      :svg-path="config.containersErrorImage"
    >
      <template #description>
        <p>
          <gl-sprintf :message="$options.i18n.CONNECTION_ERROR_MESSAGE">
            <template #docLink="{ content }">
              <gl-link :href="`${config.helpPagePath}#docker-connection-error`" target="_blank">
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </p>
      </template>
    </gl-empty-state>

    <template v-else>
      <registry-header
        :metadata-loading="isLoading"
        :images-count="containerRepositoriesCount"
        :expiration-policy="config.expirationPolicy"
        :help-page-path="config.helpPagePath"
        :hide-expiration-policy-data="config.isGroupPage"
      >
        <template #commands>
          <cli-commands v-if="showCommands" />
        </template>
      </registry-header>

      <registry-search
        :filter="filter"
        :sorting="sorting"
        :tokens="[]"
        :sortable-fields="$options.searchConfig"
        @sorting:changed="updateSorting"
        @filter:changed="filter = $event"
        @filter:submit="doFilter"
        @query:changed="updateUrlQueryString"
      />

      <div v-if="isLoading" class="gl-mt-5">
        <gl-skeleton-loader
          v-for="index in $options.loader.repeat"
          :key="index"
          :width="$options.loader.width"
          :height="$options.loader.height"
          preserve-aspect-ratio="xMinYMax meet"
        >
          <rect width="500" x="10" y="10" height="20" rx="4" />
          <circle cx="525" cy="20" r="10" />
          <rect x="960" y="0" width="40" height="40" rx="4" />
        </gl-skeleton-loader>
      </div>
      <template v-else>
        <template v-if="images.length > 0 || name">
          <image-list
            v-if="images.length"
            :images="images"
            :metadata-loading="$apollo.queries.additionalDetails.loading"
            :page-info="pageInfo"
            @delete="deleteImage"
            @prev-page="fetchPreviousPage"
            @next-page="fetchNextPage"
          />

          <gl-empty-state
            v-else
            :svg-path="config.noContainersImage"
            data-testid="emptySearch"
            :title="$options.i18n.EMPTY_RESULT_TITLE"
          >
            <template #description>
              {{ $options.i18n.EMPTY_RESULT_MESSAGE }}
            </template>
          </gl-empty-state>
        </template>
        <template v-else>
          <project-empty-state v-if="!config.isGroupPage" />
          <group-empty-state v-else />
        </template>
      </template>

      <delete-image
        :id="itemToDelete.id"
        @start="startDelete"
        @error="deleteAlertType = 'danger'"
        @success="deleteAlertType = 'success'"
        @end="mutationLoading = false"
      >
        <template #default="{ doDelete }">
          <gl-modal
            ref="deleteModal"
            modal-id="delete-image-modal"
            :action-primary="{ text: __('Remove'), attributes: { variant: 'danger' } }"
            @primary="doDelete"
            @cancel="track('cancel_delete')"
          >
            <template #modal-title>{{ $options.i18n.REMOVE_REPOSITORY_LABEL }}</template>
            <p>
              <gl-sprintf :message="$options.i18n.REMOVE_REPOSITORY_MODAL_TEXT">
                <template #title>
                  <b>{{ itemToDelete.path }}</b>
                </template>
              </gl-sprintf>
            </p>
          </gl-modal>
        </template>
      </delete-image>
    </template>
  </div>
</template>
