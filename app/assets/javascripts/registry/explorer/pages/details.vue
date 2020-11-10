<script>
import { mapState, mapActions } from 'vuex';
import { GlPagination, GlResizeObserverDirective } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import Tracking from '~/tracking';
import DeleteAlert from '../components/details_page/delete_alert.vue';
import PartialCleanupAlert from '../components/details_page/partial_cleanup_alert.vue';
import DeleteModal from '../components/details_page/delete_modal.vue';
import DetailsHeader from '../components/details_page/details_header.vue';
import TagsList from '../components/details_page/tags_list.vue';
import TagsLoader from '../components/details_page/tags_loader.vue';
import EmptyTagsState from '../components/details_page/empty_tags_state.vue';

import {
  ALERT_SUCCESS_TAG,
  ALERT_DANGER_TAG,
  ALERT_SUCCESS_TAGS,
  ALERT_DANGER_TAGS,
} from '../constants/index';

export default {
  components: {
    DeleteAlert,
    PartialCleanupAlert,
    DetailsHeader,
    GlPagination,
    DeleteModal,
    TagsList,
    TagsLoader,
    EmptyTagsState,
  },
  directives: {
    GlResizeObserver: GlResizeObserverDirective,
  },
  mixins: [Tracking.mixin()],
  data() {
    return {
      itemsToBeDeleted: [],
      isMobile: false,
      deleteAlertType: null,
      dismissPartialCleanupWarning: false,
    };
  },
  computed: {
    ...mapState(['tagsPagination', 'isLoading', 'config', 'tags', 'imageDetails']),
    showPartialCleanupWarning() {
      return this.imageDetails?.cleanup_policy_started_at && !this.dismissPartialCleanupWarning;
    },
    tracking() {
      return {
        label:
          this.itemsToBeDeleted?.length > 1 ? 'bulk_registry_tag_delete' : 'registry_tag_delete',
      };
    },
    currentPage: {
      get() {
        return this.tagsPagination.page;
      },
      set(page) {
        this.requestTagsList({ page });
      },
    },
  },
  mounted() {
    this.requestImageDetailsAndTagsList(this.$route.params.id);
  },
  methods: {
    ...mapActions([
      'requestTagsList',
      'requestDeleteTag',
      'requestDeleteTags',
      'requestImageDetailsAndTagsList',
    ]),
    deleteTags(toBeDeleted) {
      this.itemsToBeDeleted = this.tags.filter(tag => toBeDeleted[tag.name]);
      this.track('click_button');
      this.$refs.deleteModal.show();
    },
    handleSingleDelete() {
      const [itemToDelete] = this.itemsToBeDeleted;
      this.itemsToBeDeleted = [];
      return this.requestDeleteTag({ tag: itemToDelete })
        .then(() => {
          this.deleteAlertType = ALERT_SUCCESS_TAG;
        })
        .catch(() => {
          this.deleteAlertType = ALERT_DANGER_TAG;
        });
    },
    handleMultipleDelete() {
      const { itemsToBeDeleted } = this;
      this.itemsToBeDeleted = [];

      return this.requestDeleteTags({
        ids: itemsToBeDeleted.map(x => x.name),
      })
        .then(() => {
          this.deleteAlertType = ALERT_SUCCESS_TAGS;
        })
        .catch(() => {
          this.deleteAlertType = ALERT_DANGER_TAGS;
        });
    },
    onDeletionConfirmed() {
      this.track('confirm_delete');
      if (this.itemsToBeDeleted.length > 1) {
        this.handleMultipleDelete();
      } else {
        this.handleSingleDelete();
      }
    },
    handleResize() {
      this.isMobile = GlBreakpointInstance.getBreakpointSize() === 'xs';
    },
  },
};
</script>

<template>
  <div v-gl-resize-observer="handleResize" class="gl-my-3">
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
      @dismiss="dismissPartialCleanupWarning = true"
    />

    <details-header :image-name="imageDetails.name" />

    <tags-loader v-if="isLoading" />
    <template v-else>
      <empty-tags-state v-if="tags.length === 0" :no-containers-image="config.noContainersImage" />
      <tags-list v-else :tags="tags" :is-mobile="isMobile" @delete="deleteTags" />
    </template>

    <gl-pagination
      v-if="!isLoading"
      ref="pagination"
      v-model="currentPage"
      :per-page="tagsPagination.perPage"
      :total-items="tagsPagination.total"
      align="center"
      class="gl-w-full gl-mt-3"
    />

    <delete-modal
      ref="deleteModal"
      :items-to-be-deleted="itemsToBeDeleted"
      @confirmDelete="onDeletionConfirmed"
      @cancel="track('cancel_delete')"
    />
  </div>
</template>
