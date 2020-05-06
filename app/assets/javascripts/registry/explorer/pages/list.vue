<script>
import { mapState, mapActions } from 'vuex';
import {
  GlEmptyState,
  GlPagination,
  GlTooltipDirective,
  GlDeprecatedButton,
  GlIcon,
  GlModal,
  GlSprintf,
  GlLink,
  GlAlert,
  GlSkeletonLoader,
} from '@gitlab/ui';
import Tracking from '~/tracking';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ProjectEmptyState from '../components/project_empty_state.vue';
import GroupEmptyState from '../components/group_empty_state.vue';
import ProjectPolicyAlert from '../components/project_policy_alert.vue';
import QuickstartDropdown from '../components/quickstart_dropdown.vue';
import {
  DELETE_IMAGE_SUCCESS_MESSAGE,
  DELETE_IMAGE_ERROR_MESSAGE,
  ASYNC_DELETE_IMAGE_ERROR_MESSAGE,
  CONTAINER_REGISTRY_TITLE,
  CONNECTION_ERROR_TITLE,
  CONNECTION_ERROR_MESSAGE,
  LIST_INTRO_TEXT,
  LIST_DELETE_BUTTON_DISABLED,
  REMOVE_REPOSITORY_LABEL,
  REMOVE_REPOSITORY_MODAL_TEXT,
  ROW_SCHEDULED_FOR_DELETION,
} from '../constants';

export default {
  name: 'RegistryListApp',
  components: {
    GlEmptyState,
    GlPagination,
    ProjectEmptyState,
    GroupEmptyState,
    ProjectPolicyAlert,
    ClipboardButton,
    QuickstartDropdown,
    GlDeprecatedButton,
    GlIcon,
    GlModal,
    GlSprintf,
    GlLink,
    GlAlert,
    GlSkeletonLoader,
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
    containerRegistryTitle: CONTAINER_REGISTRY_TITLE,
    connectionErrorTitle: CONNECTION_ERROR_TITLE,
    connectionErrorMessage: CONNECTION_ERROR_MESSAGE,
    introText: LIST_INTRO_TEXT,
    deleteButtonDisabled: LIST_DELETE_BUTTON_DISABLED,
    removeRepositoryLabel: REMOVE_REPOSITORY_LABEL,
    removeRepositoryModalText: REMOVE_REPOSITORY_MODAL_TEXT,
    rowScheduledForDeletion: ROW_SCHEDULED_FOR_DELETION,
    asyncDeleteErrorMessage: ASYNC_DELETE_IMAGE_ERROR_MESSAGE,
  },
  data() {
    return {
      itemToDelete: {},
      deleteAlertType: null,
    };
  },
  computed: {
    ...mapState(['config', 'isLoading', 'images', 'pagination']),
    tracking() {
      return {
        label: 'registry_repository_delete',
      };
    },
    currentPage: {
      get() {
        return this.pagination.page;
      },
      set(page) {
        this.requestImagesList({ page });
      },
    },
    showQuickStartDropdown() {
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
        this.requestImagesList();
      }
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
    encodeListItem(item) {
      const params = JSON.stringify({ name: item.path, tags_path: item.tags_path, id: item.id });
      return window.btoa(params);
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

    <project-policy-alert v-if="!config.isGroupPage" class="mt-2" />

    <gl-empty-state
      v-if="config.characterError"
      :title="$options.i18n.connectionErrorTitle"
      :svg-path="config.containersErrorImage"
    >
      <template #description>
        <p>
          <gl-sprintf :message="$options.i18n.connectionErrorMessage">
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
      <div>
        <div class="d-flex justify-content-between align-items-center">
          <h4>{{ $options.i18n.containerRegistryTitle }}</h4>
          <quickstart-dropdown v-if="showQuickStartDropdown" class="d-none d-sm-block" />
        </div>
        <p>
          <gl-sprintf :message="$options.i18n.introText">
            <template #docLink="{content}">
              <gl-link :href="config.helpPagePath" target="_blank">
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </p>
      </div>

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
        <div v-if="images.length" ref="imagesList" class="d-flex flex-column">
          <div
            v-for="(listItem, index) in images"
            :key="index"
            ref="rowItem"
            v-gl-tooltip="{
              placement: 'left',
              disabled: !listItem.deleting,
              title: $options.i18n.rowScheduledForDeletion,
            }"
          >
            <div
              class="d-flex justify-content-between align-items-center py-2 px-1 border-bottom"
              :class="{ 'border-top': index === 0, 'disabled-content': listItem.deleting }"
            >
              <div class="d-felx align-items-center">
                <router-link
                  ref="detailsLink"
                  :to="{ name: 'details', params: { id: encodeListItem(listItem) } }"
                >
                  {{ listItem.path }}
                </router-link>
                <clipboard-button
                  v-if="listItem.location"
                  ref="clipboardButton"
                  :disabled="listItem.deleting"
                  :text="listItem.location"
                  :title="listItem.location"
                  css-class="btn-default btn-transparent btn-clipboard"
                />
                <gl-icon
                  v-if="listItem.failedDelete"
                  v-gl-tooltip
                  :title="$options.i18n.asyncDeleteErrorMessage"
                  name="warning"
                  class="text-warning align-middle"
                />
              </div>
              <div
                v-gl-tooltip="{ disabled: listItem.destroy_path }"
                class="d-none d-sm-block"
                :title="$options.i18n.deleteButtonDisabled"
              >
                <gl-deprecated-button
                  ref="deleteImageButton"
                  v-gl-tooltip
                  :disabled="!listItem.destroy_path || listItem.deleting"
                  :title="$options.i18n.removeRepositoryLabel"
                  :aria-label="$options.i18n.removeRepositoryLabel"
                  class="btn-inverted"
                  variant="danger"
                  @click="deleteImage(listItem)"
                >
                  <gl-icon name="remove" />
                </gl-deprecated-button>
              </div>
            </div>
          </div>
          <gl-pagination
            v-model="currentPage"
            :per-page="pagination.perPage"
            :total-items="pagination.total"
            align="center"
            class="w-100 mt-2"
          />
        </div>

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
        <template #modal-title>{{ $options.i18n.removeRepositoryLabel }}</template>
        <p>
          <gl-sprintf :message="$options.i18n.removeRepositoryModalText">
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
