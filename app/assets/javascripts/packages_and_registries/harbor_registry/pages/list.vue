<script>
import { GlEmptyState, GlSprintf, GlLink, GlSkeletonLoader } from '@gitlab/ui';
import EmptyResult from '~/vue_shared/components/empty_result.vue';
import HarborListHeader from '~/packages_and_registries/harbor_registry/components/list/harbor_list_header.vue';
import PersistedSearch from '~/packages_and_registries/shared/components/persisted_search.vue';
import HarborList from '~/packages_and_registries/harbor_registry/components/list/harbor_list.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import {
  extractSortingDetail,
  formatPagination,
  parseFilter,
  dockerBuildCommand,
  dockerPushCommand,
  dockerLoginCommand,
} from '~/packages_and_registries/harbor_registry/utils';
import { createAlert } from '~/alert';
import {
  SORT_FIELDS,
  CONNECTION_ERROR_TITLE,
  CONNECTION_ERROR_MESSAGE,
  EMPTY_RESULT_TITLE,
  EMPTY_RESULT_MESSAGE,
  DEFAULT_PER_PAGE,
  FETCH_IMAGES_LIST_ERROR_MESSAGE,
  EMPTY_IMAGES_TITLE,
  EMPTY_IMAGES_MESSAGE,
  HARBOR_REGISTRY_HELP_PAGE_PATH,
} from '~/packages_and_registries/harbor_registry/constants';
import Tracking from '~/tracking';
import { getHarborRepositoriesList } from '~/rest_api';

export default {
  name: 'HarborListPage',
  components: {
    HarborListHeader,
    HarborList,
    GlSkeletonLoader,
    GlEmptyState,
    GlSprintf,
    GlLink,
    EmptyResult,
    PersistedSearch,
    CliCommands: () =>
      import(
        /* webpackChunkName: 'harbor_registry_components' */ '~/packages_and_registries/shared/components/cli_commands.vue'
      ),
  },
  mixins: [Tracking.mixin()],
  inject: [
    'endpoint',
    'repositoryUrl',
    'harborIntegrationProjectName',
    'projectName',
    'isGroupPage',
    'connectionError',
    'invalidPathError',
    'containersErrorImage',
    'noContainersImage',
  ],
  loader: {
    repeat: 10,
    width: 1000,
    height: 40,
  },
  i18n: {
    connectionErrorTitle: CONNECTION_ERROR_TITLE,
    connectionErrorMessage: CONNECTION_ERROR_MESSAGE,
  },
  searchConfig: SORT_FIELDS,
  helpPagePath: HARBOR_REGISTRY_HELP_PAGE_PATH,
  data() {
    return {
      images: [],
      totalCount: 0,
      pageInfo: {},
      filter: [],
      isLoading: true,
      sorting: null,
      name: null,
    };
  },
  computed: {
    dockerCommand() {
      return {
        build: dockerBuildCommand({
          repositoryUrl: this.repositoryUrl,
          harborProjectName: this.harborIntegrationProjectName,
          projectName: this.projectName,
        }),
        push: dockerPushCommand({
          repositoryUrl: this.repositoryUrl,
          harborProjectName: this.harborIntegrationProjectName,
          projectName: this.projectName,
        }),
        login: dockerLoginCommand(this.repositoryUrl),
      };
    },
    showCommands() {
      return !this.isLoading && !this.isGroupPage && this.images?.length;
    },
    showConnectionError() {
      return this.connectionError || this.invalidPathError;
    },
    currentPage() {
      return this.pageInfo.page || 1;
    },
    emptyStateTexts() {
      return {
        title: this.name ? EMPTY_RESULT_TITLE : EMPTY_IMAGES_TITLE,
        message: this.name ? EMPTY_RESULT_MESSAGE : EMPTY_IMAGES_MESSAGE,
      };
    },
  },
  methods: {
    fetchHarborImages(requestPage) {
      this.isLoading = true;

      const { orderBy, sort } = extractSortingDetail(this.sorting);
      const sortOptions = `${orderBy} ${sort}`;

      const params = {
        requestPath: this.endpoint,
        limit: DEFAULT_PER_PAGE,
        search: this.name,
        page: requestPage,
        sort: sortOptions,
      };

      getHarborRepositoriesList(params)
        .then((res) => {
          this.images = (res?.data || []).map((item) => {
            return convertObjectPropsToCamelCase(item);
          });
          const pagination = formatPagination(res.headers);

          this.totalCount = pagination?.total || 0;
          this.pageInfo = pagination;

          this.isLoading = false;
        })
        .catch(() => {
          createAlert({ message: FETCH_IMAGES_LIST_ERROR_MESSAGE });
        });
    },
    handleSearchUpdate({ sort, filters }) {
      this.sorting = sort;
      this.name = parseFilter(filters, 'name');

      this.fetchHarborImages(1);
    },
    fetchPrevPage() {
      const prevPageNum = this.currentPage - 1;
      this.fetchHarborImages(prevPageNum);
    },
    fetchNextPage() {
      const nextPageNum = this.currentPage + 1;
      this.fetchHarborImages(nextPageNum);
    },
  },
};
</script>

<template>
  <div>
    <gl-empty-state
      v-if="showConnectionError"
      :title="$options.i18n.connectionErrorTitle"
      :svg-path="containersErrorImage"
    >
      <template #description>
        <p>
          <gl-sprintf :message="$options.i18n.connectionErrorMessage">
            <template #docLink="{ content }">
              <gl-link :href="$options.helpPagePath" target="_blank">
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </p>
      </template>
    </gl-empty-state>
    <template v-else>
      <harbor-list-header :metadata-loading="isLoading" :images-count="totalCount">
        <template #commands>
          <cli-commands
            v-if="showCommands"
            :docker-build-command="dockerCommand.build"
            :docker-push-command="dockerCommand.push"
            :docker-login-command="dockerCommand.login"
          />
        </template>
      </harbor-list-header>
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
        <harbor-list
          v-if="images.length"
          :images="images"
          :metadata-loading="isLoading"
          :page-info="pageInfo"
          @prev-page="fetchPrevPage"
          @next-page="fetchNextPage"
        />
        <empty-result v-else-if="name" data-testid="emptySearch" />
        <gl-empty-state
          v-else
          :svg-path="noContainersImage"
          data-testid="emptySearch"
          :title="emptyStateTexts.title"
        >
          <template #description>
            {{ emptyStateTexts.message }}
          </template>
        </gl-empty-state>
      </template>
    </template>
  </div>
</template>
