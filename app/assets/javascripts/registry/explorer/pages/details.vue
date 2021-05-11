<script>
import { GlResizeObserverDirective } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import Tracking from '~/tracking';
import DeleteImage from '../components/delete_image.vue';
import DeleteAlert from '../components/details_page/delete_alert.vue';
import DeleteModal from '../components/details_page/delete_modal.vue';
import DetailsHeader from '../components/details_page/details_header.vue';
import EmptyState from '../components/details_page/empty_state.vue';
import PartialCleanupAlert from '../components/details_page/partial_cleanup_alert.vue';
import StatusAlert from '../components/details_page/status_alert.vue';
import TagsList from '../components/details_page/tags_list.vue';
import TagsLoader from '../components/details_page/tags_loader.vue';

import {
  ALERT_SUCCESS_TAG,
  ALERT_DANGER_TAG,
  ALERT_SUCCESS_TAGS,
  ALERT_DANGER_TAGS,
  ALERT_DANGER_IMAGE,
  FETCH_IMAGES_LIST_ERROR_MESSAGE,
  UNFINISHED_STATUS,
  MISSING_OR_DELETED_IMAGE_BREADCRUMB,
  ROOT_IMAGE_TEXT,
} from '../constants/index';
import deleteContainerRepositoryTagsMutation from '../graphql/mutations/delete_container_repository_tags.mutation.graphql';
import getContainerRepositoryDetailsQuery from '../graphql/queries/get_container_repository_details.query.graphql';

export default {
  name: 'RegistryDetailsPage',
  components: {
    DeleteAlert,
    PartialCleanupAlert,
    DetailsHeader,
    DeleteModal,
    TagsList,
    TagsLoader,
    EmptyState,
    StatusAlert,
    DeleteImage,
  },
  directives: {
    GlResizeObserver: GlResizeObserverDirective,
  },
  mixins: [Tracking.mixin()],
  inject: ['breadCrumbState', 'config'],
  apollo: {
    containerRepository: {
      query: getContainerRepositoryDetailsQuery,
      variables() {
        return this.queryVariables;
      },
      result() {
        this.updateBreadcrumb();
      },
      error() {
        createFlash({ message: FETCH_IMAGES_LIST_ERROR_MESSAGE });
      },
    },
  },
  data() {
    return {
      containerRepository: {},
      itemsToBeDeleted: [],
      isMobile: false,
      mutationLoading: false,
      deleteAlertType: null,
      hidePartialCleanupWarning: false,
      deleteImageAlert: false,
    };
  },
  computed: {
    queryVariables() {
      return {
        id: joinPaths(this.config.gidPrefix, `${this.$route.params.id}`),
      };
    },
    isLoading() {
      return this.$apollo.queries.containerRepository.loading || this.mutationLoading;
    },
    showPartialCleanupWarning() {
      return (
        this.config.showUnfinishedTagCleanupCallout &&
        this.containerRepository?.expirationPolicyCleanupStatus === UNFINISHED_STATUS &&
        !this.hidePartialCleanupWarning
      );
    },
    tracking() {
      return {
        label:
          this.itemsToBeDeleted?.length > 1 ? 'bulk_registry_tag_delete' : 'registry_tag_delete',
      };
    },
    pageActionsAreDisabled() {
      return Boolean(this.containerRepository?.status);
    },
  },
  methods: {
    updateBreadcrumb() {
      const name = this.containerRepository?.id
        ? this.containerRepository?.name || ROOT_IMAGE_TEXT
        : MISSING_OR_DELETED_IMAGE_BREADCRUMB;
      this.breadCrumbState.updateName(name);
    },
    deleteTags(toBeDeleted) {
      this.deleteImageAlert = false;
      this.itemsToBeDeleted = toBeDeleted;
      this.track('click_button');
      this.$refs.deleteModal.show();
    },
    confirmDelete() {
      if (this.deleteImageAlert) {
        this.$refs.deleteImage.doDelete();
      } else {
        this.handleDeleteTag();
      }
    },
    async handleDeleteTag() {
      this.track('confirm_delete');
      const { itemsToBeDeleted } = this;
      this.itemsToBeDeleted = [];
      this.mutationLoading = true;
      try {
        const { data } = await this.$apollo.mutate({
          mutation: deleteContainerRepositoryTagsMutation,
          variables: {
            id: this.queryVariables.id,
            tagNames: itemsToBeDeleted.map((i) => i.name),
          },
          awaitRefetchQueries: true,
          refetchQueries: [
            {
              query: getContainerRepositoryDetailsQuery,
              variables: this.queryVariables,
            },
          ],
        });

        if (data?.destroyContainerRepositoryTags?.errors[0]) {
          throw new Error();
        }
        this.deleteAlertType =
          itemsToBeDeleted.length === 0 ? ALERT_SUCCESS_TAG : ALERT_SUCCESS_TAGS;
      } catch (e) {
        this.deleteAlertType = itemsToBeDeleted.length === 0 ? ALERT_DANGER_TAG : ALERT_DANGER_TAGS;
      }

      this.mutationLoading = false;
    },
    handleResize() {
      this.isMobile = GlBreakpointInstance.getBreakpointSize() === 'xs';
    },
    dismissPartialCleanupWarning() {
      this.hidePartialCleanupWarning = true;
      axios.post(this.config.userCalloutsPath, {
        feature_name: this.config.userCalloutId,
      });
    },
    deleteImage() {
      this.deleteImageAlert = true;
      this.itemsToBeDeleted = [{ path: this.containerRepository.path }];
      this.$refs.deleteModal.show();
    },
    deleteImageError() {
      this.deleteAlertType = ALERT_DANGER_IMAGE;
    },
    deleteImageIniit() {
      this.itemsToBeDeleted = [];
      this.mutationLoading = true;
    },
  },
};
</script>

<template>
  <div v-gl-resize-observer="handleResize" class="gl-my-3">
    <template v-if="containerRepository">
      <delete-alert
        v-model="deleteAlertType"
        :garbage-collection-help-page-path="config.garbageCollectionHelpPagePath"
        :is-admin="config.isAdmin"
        class="gl-my-2"
      />

      <partial-cleanup-alert
        v-if="showPartialCleanupWarning"
        :run-cleanup-policies-help-page-path="config.runCleanupPoliciesHelpPagePath"
        :cleanup-policies-help-page-path="config.cleanupPoliciesHelpPagePath"
        @dismiss="dismissPartialCleanupWarning"
      />

      <status-alert v-if="containerRepository.status" :status="containerRepository.status" />

      <details-header
        v-if="!isLoading"
        :image="containerRepository"
        :disabled="pageActionsAreDisabled"
        @delete="deleteImage"
      />

      <tags-loader v-if="isLoading" />
      <tags-list
        v-else
        :id="$route.params.id"
        :is-image-loading="isLoading"
        :is-mobile="isMobile"
        :disabled="pageActionsAreDisabled"
        @delete="deleteTags"
      />

      <delete-image
        :id="containerRepository.id"
        ref="deleteImage"
        use-update-fn
        @start="deleteImageIniit"
        @error="deleteImageError"
        @end="mutationLoading = false"
      />

      <delete-modal
        ref="deleteModal"
        :items-to-be-deleted="itemsToBeDeleted"
        :delete-image="deleteImageAlert"
        @confirmDelete="confirmDelete"
        @cancel="track('cancel_delete')"
      />
    </template>
    <empty-state v-else is-empty-image :no-containers-image="config.noContainersImage" />
  </div>
</template>
