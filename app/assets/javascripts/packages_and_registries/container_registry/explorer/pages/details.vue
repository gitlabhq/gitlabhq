<script>
import { GlResizeObserverDirective, GlEmptyState, GlSkeletonLoader } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import Tracking from '~/tracking';
import { helpPagePath } from '~/helpers/help_page_helper';
import DeleteImage from '../components/delete_image.vue';
import DeleteAlert from '../components/details_page/delete_alert.vue';
import DeleteModal from '../components/delete_modal.vue';
import DetailsHeader from '../components/details_page/details_header.vue';
import PartialCleanupAlert from '../components/details_page/partial_cleanup_alert.vue';
import StatusAlert from '../components/details_page/status_alert.vue';
import TagsList from '../components/details_page/tags_list.vue';

import {
  ALERT_DANGER_IMAGE,
  FETCH_IMAGES_LIST_ERROR_MESSAGE,
  UNFINISHED_STATUS,
  MISSING_OR_DELETED_IMAGE_BREADCRUMB,
  MISSING_OR_DELETED_IMAGE_TITLE,
  MISSING_OR_DELETED_IMAGE_MESSAGE,
} from '../constants/index';
import getContainerRepositoryDetailsQuery from '../graphql/queries/get_container_repository_details.query.graphql';

export default {
  name: 'RegistryDetailsPage',
  components: {
    GlEmptyState,
    GlSkeletonLoader,
    DeleteAlert,
    PartialCleanupAlert,
    DetailsHeader,
    DeleteModal,
    TagsList,
    StatusAlert,
    DeleteImage,
  },
  directives: {
    GlResizeObserver: GlResizeObserverDirective,
  },
  mixins: [Tracking.mixin()],
  inject: ['breadCrumbState', 'config'],
  i18n: {
    MISSING_OR_DELETED_IMAGE_TITLE,
    MISSING_OR_DELETED_IMAGE_MESSAGE,
  },
  cleanupPoliciesHelpUrl: helpPagePath(
    'user/packages/container_registry/reduce_container_registry_storage',
    {
      anchor: 'cleanup-policy',
    },
  ),
  garbageCollectionHelpUrl: helpPagePath('administration/packages/container_registry', {
    anchor: 'container-registry-garbage-collection',
  }),
  runCleanupPoliciesHelpUrl: helpPagePath('administration/packages/container_registry', {
    anchor: 'run-the-cleanup-policy',
  }),
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
        createAlert({ message: FETCH_IMAGES_LIST_ERROR_MESSAGE });
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
        label: 'registry_image_delete',
      };
    },
    pageActionsAreDisabled() {
      return Boolean(this.containerRepository?.status);
    },
  },
  methods: {
    updateBreadcrumb() {
      const name = this.containerRepository?.id
        ? this.containerRepository?.name || this.containerRepository?.project?.path
        : MISSING_OR_DELETED_IMAGE_BREADCRUMB;
      this.breadCrumbState.updateName(name);
    },
    confirmDelete() {
      this.$refs.deleteImage.doDelete();
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
      this.itemsToBeDeleted = [{ ...this.containerRepository }];
      this.$refs.deleteModal.show();
    },
    deleteImageError() {
      this.deleteAlertType = ALERT_DANGER_IMAGE;
    },
    deleteImageIniit() {
      this.itemsToBeDeleted = [];
      this.mutationLoading = true;
    },
    showAlert(alertType) {
      this.deleteAlertType = alertType;
    },
  },
};
</script>

<template>
  <div v-gl-resize-observer="handleResize" class="gl-my-3">
    <template v-if="containerRepository">
      <delete-alert
        v-model="deleteAlertType"
        :garbage-collection-help-page-path="$options.garbageCollectionHelpUrl"
        :is-admin="config.isAdmin"
        class="gl-my-2"
      />

      <partial-cleanup-alert
        v-if="showPartialCleanupWarning"
        :run-cleanup-policies-help-page-path="$options.runCleanupPoliciesHelpUrl"
        :cleanup-policies-help-page-path="$options.cleanupPoliciesHelpUrl"
        @dismiss="dismissPartialCleanupWarning"
      />

      <status-alert v-if="containerRepository.status" :status="containerRepository.status" />

      <div v-if="isLoading" class="gl-my-6">
        <gl-skeleton-loader />
      </div>
      <details-header
        v-else
        :image="containerRepository"
        :disabled="pageActionsAreDisabled"
        @delete="deleteImage"
      />

      <tags-list
        :id="$route.params.id"
        :is-image-loading="isLoading"
        :is-mobile="isMobile"
        :disabled="pageActionsAreDisabled"
        @delete="showAlert"
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
        delete-image
        @confirmDelete="confirmDelete"
        @cancel="track('cancel_delete')"
      />
    </template>
    <gl-empty-state
      v-else
      :title="$options.i18n.MISSING_OR_DELETED_IMAGE_TITLE"
      :description="$options.i18n.MISSING_OR_DELETED_IMAGE_MESSAGE"
      :svg-path="config.noContainersImage"
      :svg-height="null"
      class="gl-mx-auto gl-my-0"
    />
  </div>
</template>
