<script>
import {
  GlButton,
  GlEmptyState,
  GlTooltipDirective,
  GlSprintf,
  GlLink,
  GlAlert,
  GlSkeletonLoader,
} from '@gitlab/ui';
import { get } from 'lodash';
import getContainerRepositoriesQuery from 'shared_queries/container_registry/get_container_repositories.query.graphql';
import { createAlert } from '~/alert';
import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import { fetchPolicies } from '~/lib/graphql';
import Tracking from '~/tracking';
import PersistedPagination from '~/packages_and_registries/shared/components/persisted_pagination.vue';
import PersistedSearch from '~/packages_and_registries/shared/components/persisted_search.vue';
import MetadataDatabaseAlert from '~/packages_and_registries/shared/components/container_registry_metadata_database_alert.vue';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import { helpPagePath } from '~/helpers/help_page_helper';
import DeleteImage from '../components/delete_image.vue';
import RegistryHeader from '../components/list_page/registry_header.vue';
import DeleteModal from '../components/delete_modal.vue';
import {
  DELETE_IMAGE_SUCCESS_MESSAGE,
  DELETE_IMAGE_ERROR_MESSAGE,
  CONNECTION_ERROR_TITLE,
  CONNECTION_ERROR_MESSAGE,
  EMPTY_RESULT_TITLE,
  EMPTY_RESULT_MESSAGE,
  GRAPHQL_PAGE_SIZE,
  GRAPHQL_PAGE_SIZE_METADATA_ENABLED,
  FETCH_IMAGES_LIST_ERROR_MESSAGE,
  SORT_FIELDS,
  SETTINGS_TEXT,
} from '../constants/index';
import getContainerRepositoriesDetails from '../graphql/queries/get_container_repositories_details.query.graphql';
import { getPageParams, getNextPageParams, getPreviousPageParams } from '../utils';

export default {
  name: 'RegistryListPage',
  components: {
    GlButton,
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
        /* webpackChunkName: 'container_registry_components' */ '~/packages_and_registries/shared/components/cli_commands.vue'
      ),
    DeleteModal,
    GlSprintf,
    GlLink,
    GlAlert,
    GlSkeletonLoader,
    RegistryHeader,
    DeleteImage,
    MetadataDatabaseAlert,
    PersistedPagination,
    PersistedSearch,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin()],
  inject: ['config', 'dockerBuildCommand', 'dockerPushCommand', 'dockerLoginCommand'],
  loader: {
    repeat: 10,
    width: 1000,
    height: 40,
  },
  i18n: {
    CONNECTION_ERROR_TITLE,
    CONNECTION_ERROR_MESSAGE,
    EMPTY_RESULT_TITLE,
    EMPTY_RESULT_MESSAGE,
    SETTINGS_TEXT,
  },
  searchConfig: SORT_FIELDS,
  apollo: {
    baseImages: {
      skip() {
        return !this.fetchBaseQuery;
      },
      query: getContainerRepositoriesQuery,
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data[this.graphqlResource]?.containerRepositories?.nodes ?? [];
      },
      result({ data }) {
        if (!data) {
          return;
        }
        this.pageInfo = data[this.graphqlResource]?.containerRepositories?.pageInfo;
        this.containerRepositoriesCount = data[this.graphqlResource]?.containerRepositoriesCount;
      },
      error() {
        createAlert({ message: FETCH_IMAGES_LIST_ERROR_MESSAGE });
      },
    },
    additionalDetails: {
      skip() {
        return !this.fetchAdditionalDetails;
      },
      query: getContainerRepositoriesDetails,
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data[this.graphqlResource]?.containerRepositories?.nodes ?? [];
      },
      error() {
        createAlert({ message: FETCH_IMAGES_LIST_ERROR_MESSAGE });
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
      sorting: null,
      name: null,
      mutationLoading: false,
      fetchBaseQuery: false,
      fetchAdditionalDetails: false,
      pageParams: {},
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
    itemsToBeDeleted() {
      return this.itemToDelete?.id ? [this.itemToDelete] : [];
    },
    graphqlResource() {
      return this.config.isGroupPage ? WORKSPACE_GROUP : WORKSPACE_PROJECT;
    },
    pageSize() {
      return this.config.isMetadataDatabaseEnabled
        ? GRAPHQL_PAGE_SIZE_METADATA_ENABLED
        : GRAPHQL_PAGE_SIZE;
    },
    queryVariables() {
      return {
        name: this.name,
        sort: this.sorting,
        fullPath: this.config.isGroupPage ? this.config.groupPath : this.config.projectPath,
        isGroupPage: this.config.isGroupPage,
        first: this.pageSize,
        ...this.pageParams,
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
    showConnectionError() {
      return this.config.connectionError || this.config.invalidPathError;
    },
    deleteImageAlertMessage() {
      return this.deleteAlertType === 'success'
        ? DELETE_IMAGE_SUCCESS_MESSAGE
        : DELETE_IMAGE_ERROR_MESSAGE;
    },
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
    fetchNextPage() {
      this.pageParams = getNextPageParams(this.pageInfo?.endCursor, this.pageSize);
    },
    fetchPreviousPage() {
      this.pageParams = getPreviousPageParams(this.pageInfo?.startCursor, this.pageSize);
    },
    startDelete() {
      this.track('confirm_delete');
      this.mutationLoading = true;
    },
    handleSearchUpdate({ sort, filters, pageInfo }) {
      this.pageParams = getPageParams(pageInfo, this.pageSize);
      this.sorting = sort;

      const search = filters.find((i) => i.type === FILTERED_SEARCH_TERM);
      this.name = search?.value?.data;

      if (!this.fetchBaseQuery && !this.fetchAdditionalDetails) {
        // If the two graphql calls - which are not batched - resolve together we will have a race
        // condition when apollo sets the cache, with this we give the 'base' call an headstart
        this.fetchBaseQuery = true;
        setTimeout(() => {
          this.fetchAdditionalDetails = true;
        }, 200);
      }
    },
  },
  containerRegistryHelpUrl: helpPagePath('user/packages/container_registry/_index'),
  dockerConnectionErrorHelpUrl: helpPagePath(
    'user/packages/container_registry/troubleshoot_container_registry',
    {
      anchor: 'docker-connection-error',
    },
  ),
};
</script>

<template>
  <div>
    <metadata-database-alert v-if="!config.isMetadataDatabaseEnabled" />
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

    <gl-empty-state
      v-if="showConnectionError"
      :title="$options.i18n.CONNECTION_ERROR_TITLE"
      :svg-path="config.containersErrorImage"
      :svg-height="null"
    >
      <template #description>
        <p>
          <gl-sprintf :message="$options.i18n.CONNECTION_ERROR_MESSAGE">
            <template #docLink="{ content }">
              <gl-link :href="$options.dockerContainerErrorHelpUrl" target="_blank">
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
        :help-page-path="$options.containerRegistryHelpUrl"
        :hide-expiration-policy-data="config.isGroupPage"
        :cleanup-policies-settings-path="config.cleanupPoliciesSettingsPath"
        :show-cleanup-policy-link="config.showCleanupPolicyLink"
      >
        <template #commands>
          <cli-commands
            v-if="showCommands"
            :docker-build-command="dockerBuildCommand"
            :docker-push-command="dockerPushCommand"
            :docker-login-command="dockerLoginCommand"
          />
          <gl-button
            v-if="config.showContainerRegistrySettings"
            v-gl-tooltip="$options.i18n.SETTINGS_TEXT"
            icon="settings"
            :href="config.settingsPath"
            :aria-label="$options.i18n.SETTINGS_TEXT"
          />
        </template>
      </registry-header>
      <persisted-search
        :sortable-fields="$options.searchConfig"
        :default-order="$options.searchConfig[0].orderBy"
        default-sort="desc"
        @update="handleSearchUpdate"
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
            :expiration-policy="config.expirationPolicy"
            @delete="deleteImage"
          />

          <gl-empty-state
            v-else
            :svg-path="config.noContainersImage"
            :svg-height="null"
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

      <div v-if="!mutationLoading" class="gl-flex gl-justify-center">
        <persisted-pagination
          class="gl-mt-3"
          :pagination="pageInfo"
          @prev="fetchPreviousPage"
          @next="fetchNextPage"
        />
      </div>

      <delete-image
        :id="itemToDelete.id"
        @start="startDelete"
        @error="deleteAlertType = 'danger'"
        @success="deleteAlertType = 'success'"
        @end="mutationLoading = false"
      >
        <template #default="{ doDelete }">
          <delete-modal
            ref="deleteModal"
            :items-to-be-deleted="itemsToBeDeleted"
            delete-image
            @confirmDelete="doDelete"
            @cancel="track('cancel_delete')"
          />
        </template>
      </delete-image>
    </template>
  </div>
</template>
