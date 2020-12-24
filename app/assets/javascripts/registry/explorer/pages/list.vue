<script>
import {
  GlEmptyState,
  GlTooltipDirective,
  GlModal,
  GlSprintf,
  GlLink,
  GlAlert,
  GlSkeletonLoader,
  GlSearchBoxByClick,
} from '@gitlab/ui';
import Tracking from '~/tracking';
import createFlash from '~/flash';

import ProjectEmptyState from '../components/list_page/project_empty_state.vue';
import GroupEmptyState from '../components/list_page/group_empty_state.vue';
import RegistryHeader from '../components/list_page/registry_header.vue';
import ImageList from '../components/list_page/image_list.vue';
import CliCommands from '../components/list_page/cli_commands.vue';

import getProjectContainerRepositoriesQuery from '../graphql/queries/get_project_container_repositories.query.graphql';
import getGroupContainerRepositoriesQuery from '../graphql/queries/get_group_container_repositories.query.graphql';
import deleteContainerRepositoryMutation from '../graphql/mutations/delete_container_repository.mutation.graphql';

import {
  DELETE_IMAGE_SUCCESS_MESSAGE,
  DELETE_IMAGE_ERROR_MESSAGE,
  CONNECTION_ERROR_TITLE,
  CONNECTION_ERROR_MESSAGE,
  REMOVE_REPOSITORY_MODAL_TEXT,
  REMOVE_REPOSITORY_LABEL,
  SEARCH_PLACEHOLDER_TEXT,
  IMAGE_REPOSITORY_LIST_LABEL,
  EMPTY_RESULT_TITLE,
  EMPTY_RESULT_MESSAGE,
  GRAPHQL_PAGE_SIZE,
  FETCH_IMAGES_LIST_ERROR_MESSAGE,
} from '../constants/index';

export default {
  name: 'RegistryListPage',
  components: {
    GlEmptyState,
    ProjectEmptyState,
    GroupEmptyState,
    ImageList,
    GlModal,
    GlSprintf,
    GlLink,
    GlAlert,
    GlSkeletonLoader,
    GlSearchBoxByClick,
    RegistryHeader,
    CliCommands,
  },
  inject: ['config'],
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin()],
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
    SEARCH_PLACEHOLDER_TEXT,
    IMAGE_REPOSITORY_LIST_LABEL,
    EMPTY_RESULT_TITLE,
    EMPTY_RESULT_MESSAGE,
  },
  apollo: {
    images: {
      query() {
        return this.graphQlQuery;
      },
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
  },
  data() {
    return {
      images: [],
      pageInfo: {},
      containerRepositoriesCount: 0,
      itemToDelete: {},
      deleteAlertType: null,
      searchValue: null,
      name: null,
      mutationLoading: false,
    };
  },
  computed: {
    graphqlResource() {
      return this.config.isGroupPage ? 'group' : 'project';
    },
    graphQlQuery() {
      return this.config.isGroupPage
        ? getGroupContainerRepositoriesQuery
        : getProjectContainerRepositoriesQuery;
    },
    queryVariables() {
      return {
        name: this.name,
        fullPath: this.config.isGroupPage ? this.config.groupPath : this.config.projectPath,
        first: GRAPHQL_PAGE_SIZE,
      };
    },
    tracking() {
      return {
        label: 'registry_repository_delete',
      };
    },
    isLoading() {
      return this.$apollo.queries.images.loading || this.mutationLoading;
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
  },
  methods: {
    deleteImage(item) {
      this.track('click_button');
      this.itemToDelete = item;
      this.$refs.deleteModal.show();
    },
    handleDeleteImage() {
      this.track('confirm_delete');
      this.mutationLoading = true;
      return this.$apollo
        .mutate({
          mutation: deleteContainerRepositoryMutation,
          variables: {
            id: this.itemToDelete.id,
          },
        })
        .then(({ data }) => {
          if (data?.destroyContainerRepository?.errors[0]) {
            this.deleteAlertType = 'danger';
          } else {
            this.deleteAlertType = 'success';
          }
        })
        .catch(() => {
          this.deleteAlertType = 'danger';
        })
        .finally(() => {
          this.mutationLoading = false;
        });
    },
    dismissDeleteAlert() {
      this.deleteAlertType = null;
      this.itemToDelete = {};
    },
    fetchNextPage() {
      if (this.pageInfo?.hasNextPage) {
        this.$apollo.queries.images.fetchMore({
          variables: {
            after: this.pageInfo?.endCursor,
            first: GRAPHQL_PAGE_SIZE,
          },
          updateQuery(previousResult, { fetchMoreResult }) {
            return fetchMoreResult;
          },
        });
      }
    },
    fetchPreviousPage() {
      if (this.pageInfo?.hasPreviousPage) {
        this.$apollo.queries.images.fetchMore({
          variables: {
            first: null,
            before: this.pageInfo?.startCursor,
            last: GRAPHQL_PAGE_SIZE,
          },
          updateQuery(previousResult, { fetchMoreResult }) {
            return fetchMoreResult;
          },
        });
      }
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
        :expiration-policy-help-page-path="config.expirationPolicyHelpPagePath"
        :hide-expiration-policy-data="config.isGroupPage"
      >
        <template #commands>
          <cli-commands v-if="showCommands" />
        </template>
      </registry-header>

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
          <div class="gl-display-flex gl-p-1 gl-mt-3" data-testid="listHeader">
            <div class="gl-flex-fill-1">
              <h5>{{ $options.i18n.IMAGE_REPOSITORY_LIST_LABEL }}</h5>
            </div>
            <div>
              <gl-search-box-by-click
                v-model="searchValue"
                :placeholder="$options.i18n.SEARCH_PLACEHOLDER_TEXT"
                @clear="name = null"
                @submit="name = $event"
              />
            </div>
          </div>

          <image-list
            v-if="images.length"
            :images="images"
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

      <gl-modal
        ref="deleteModal"
        modal-id="delete-image-modal"
        ok-variant="danger"
        @ok="handleDeleteImage"
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
        <template #modal-ok>{{ __('Remove') }}</template>
      </gl-modal>
    </template>
  </div>
</template>
