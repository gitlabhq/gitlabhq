<script>
import { mapState, mapActions } from 'vuex';
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

import ProjectEmptyState from '../components/list_page/project_empty_state.vue';
import GroupEmptyState from '../components/list_page/group_empty_state.vue';
import RegistryHeader from '../components/list_page/registry_header.vue';
import ImageList from '../components/list_page/image_list.vue';
import CliCommands from '../components/list_page/cli_commands.vue';

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
} from '../constants/index';

export default {
  name: 'RegistryListApp',
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
  data() {
    return {
      itemToDelete: {},
      deleteAlertType: null,
      search: null,
      isEmpty: false,
    };
  },
  computed: {
    ...mapState(['config', 'isLoading', 'images', 'pagination']),
    tracking() {
      return {
        label: 'registry_repository_delete',
      };
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
  mounted() {
    this.loadImageList(this.$route.name);
  },
  methods: {
    ...mapActions(['requestImagesList', 'requestDeleteImage']),
    loadImageList(fromName) {
      if (!fromName || !this.images?.length) {
        return this.requestImagesList().then(() => {
          this.isEmpty = this.images.length === 0;
        });
      }
      return Promise.resolve();
    },
    deleteImage(item) {
      this.track('click_button');
      this.itemToDelete = item;
      this.$refs.deleteModal.show();
    },
    handleDeleteImage() {
      this.track('confirm_delete');
      return this.requestDeleteImage(this.itemToDelete)
        .then(() => {
          this.deleteAlertType = 'success';
        })
        .catch(() => {
          this.deleteAlertType = 'danger';
        });
    },
    dismissDeleteAlert() {
      this.deleteAlertType = null;
      this.itemToDelete = {};
    },
  },
};
</script>

<template>
  <div class="w-100 slide-enter-from-element">
    <gl-alert
      v-if="showDeleteAlert"
      :variant="deleteAlertType"
      class="mt-2"
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
            <template #docLink="{content}">
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
        :images-count="pagination.total"
        :expiration-policy="config.expirationPolicy"
        :help-page-path="config.helpPagePath"
        :expiration-policy-help-page-path="config.expirationPolicyHelpPagePath"
        :hide-expiration-policy-data="config.isGroupPage"
      >
        <template #commands>
          <cli-commands v-if="showCommands" />
        </template>
      </registry-header>

      <div v-if="isLoading" class="mt-2">
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
        <template v-if="!isEmpty">
          <div class="gl-display-flex gl-p-1 gl-mt-3" data-testid="listHeader">
            <div class="gl-flex-fill-1">
              <h5>{{ $options.i18n.IMAGE_REPOSITORY_LIST_LABEL }}</h5>
            </div>
            <div>
              <gl-search-box-by-click
                v-model="search"
                :placeholder="$options.i18n.SEARCH_PLACEHOLDER_TEXT"
                @submit="requestImagesList({ name: $event })"
              />
            </div>
          </div>

          <image-list
            v-if="images.length"
            :images="images"
            :pagination="pagination"
            @pageChange="requestImagesList({ pagination: { page: $event }, name: search })"
            @delete="deleteImage"
          />

          <gl-empty-state
            v-else
            :svg-path="config.noContainersImage"
            data-testid="emptySearch"
            :title="$options.i18n.EMPTY_RESULT_TITLE"
            class="container-message"
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
