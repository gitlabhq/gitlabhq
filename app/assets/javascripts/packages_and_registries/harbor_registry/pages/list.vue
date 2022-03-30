<script>
import { GlEmptyState, GlSprintf, GlLink, GlSkeletonLoader } from '@gitlab/ui';
import HarborListHeader from '~/packages_and_registries/harbor_registry/components/list/harbor_list_header.vue';
import PersistedSearch from '~/packages_and_registries/shared/components/persisted_search.vue';
import HarborList from '~/packages_and_registries/harbor_registry/components/list/harbor_list.vue';
import { FILTERED_SEARCH_TERM } from '~/packages_and_registries/shared/constants';
import {
  SORT_FIELDS,
  CONNECTION_ERROR_TITLE,
  CONNECTION_ERROR_MESSAGE,
  EMPTY_RESULT_TITLE,
  EMPTY_RESULT_MESSAGE,
} from '~/packages_and_registries/harbor_registry/constants';
import Tracking from '~/tracking';
import { harborListResponse } from '../mock_api';

export default {
  name: 'HarborListPage',
  components: {
    HarborListHeader,
    HarborList,
    GlSkeletonLoader,
    GlEmptyState,
    GlSprintf,
    GlLink,
    PersistedSearch,
    CliCommands: () =>
      import(
        /* webpackChunkName: 'harbor_registry_components' */ '~/packages_and_registries/shared/components/cli_commands.vue'
      ),
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
  },
  searchConfig: SORT_FIELDS,
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
    showCommands() {
      return !this.isLoading && !this.config?.isGroupPage && this.images?.length;
    },
    showConnectionError() {
      return this.config.connectionError || this.config.invalidPathError;
    },
  },
  methods: {
    fetchHarborImages() {
      // TODO: Waiting for harbor api integration to finish: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/82777
      this.isLoading = true;

      harborListResponse()
        .then((res) => {
          this.images = res?.repositories || [];
          this.totalCount = res?.totalCount || 0;
          this.pageInfo = res?.pageInfo || {};
          this.isLoading = false;
        })
        .catch(() => {});
    },
    handleSearchUpdate({ sort, filters }) {
      this.sorting = sort;

      const search = filters.find((i) => i.type === FILTERED_SEARCH_TERM);
      this.name = search?.value?.data;

      this.fetchHarborImages();
    },
    fetchPrevPage() {
      // TODO: Waiting for harbor api integration to finish: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/82777
      this.fetchHarborImages();
    },
    fetchNextPage() {
      // TODO: Waiting for harbor api integration to finish: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/82777
      this.fetchHarborImages();
    },
  },
};
</script>

<template>
  <div>
    <gl-empty-state
      v-if="showConnectionError"
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
      <harbor-list-header
        :metadata-loading="isLoading"
        :images-count="totalCount"
        :help-page-path="config.helpPagePath"
      >
        <template #commands>
          <cli-commands
            v-if="showCommands"
            :docker-build-command="dockerBuildCommand"
            :docker-push-command="dockerPushCommand"
            :docker-login-command="dockerLoginCommand"
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
        <template v-if="images.length > 0 || name">
          <harbor-list
            v-if="images.length"
            :images="images"
            :meta-data-loading="isLoading"
            :page-info="pageInfo"
            @prev-page="fetchPrevPage"
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
      </template>
    </template>
  </div>
</template>
