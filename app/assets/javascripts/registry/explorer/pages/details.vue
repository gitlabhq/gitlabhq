<script>
import { mapState, mapActions } from 'vuex';
import { GlPagination, GlResizeObserverDirective } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import Tracking from '~/tracking';
import DeleteAlert from '../components/details_page/delete_alert.vue';
import DeleteModal from '../components/details_page/delete_modal.vue';
import DetailsHeader from '../components/details_page/details_header.vue';
import TagsTable from '../components/details_page/tags_table.vue';
import TagsLoader from '../components/details_page/tags_loader.vue';
import EmptyTagsState from '../components/details_page/empty_tags_state.vue';

import { decodeAndParse } from '../utils';
import {
  ALERT_SUCCESS_TAG,
  ALERT_DANGER_TAG,
  ALERT_SUCCESS_TAGS,
  ALERT_DANGER_TAGS,
} from '../constants/index';

export default {
  components: {
    DeleteAlert,
    DetailsHeader,
    GlPagination,
    DeleteModal,
    TagsTable,
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
      isDesktop: true,
      deleteAlertType: null,
    };
  },
  computed: {
    ...mapState(['tagsPagination', 'isLoading', 'config', 'tags']),
    imageName() {
      const { name } = decodeAndParse(this.$route.params.id);
      return name;
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
        this.requestTagsList({ pagination: { page }, params: this.$route.params.id });
      },
    },
  },
  mounted() {
    this.requestTagsList({ params: this.$route.params.id });
  },
  methods: {
    ...mapActions(['requestTagsList', 'requestDeleteTag', 'requestDeleteTags']),
    deleteTags(toBeDeletedList) {
      this.itemsToBeDeleted = toBeDeletedList.map(name => ({
        ...this.tags.find(t => t.name === name),
      }));
      this.track('click_button');
      this.$refs.deleteModal.show();
    },
    handleSingleDelete() {
      const [itemToDelete] = this.itemsToBeDeleted;
      this.itemsToBeDeleted = [];
      return this.requestDeleteTag({ tag: itemToDelete, params: this.$route.params.id })
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
        params: this.$route.params.id,
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
      this.isDesktop = GlBreakpointInstance.isDesktop();
    },
  },
};
</script>

<template>
  <div v-gl-resize-observer="handleResize" class="my-3 w-100 slide-enter-to-element">
    <delete-alert
      v-model="deleteAlertType"
      :garbage-collection-help-page-path="config.garbageCollectionHelpPagePath"
      :is-admin="config.isAdmin"
      class="my-2"
    />

    <details-header :image-name="imageName" />

    <tags-table :tags="tags" :is-loading="isLoading" :is-desktop="isDesktop" @delete="deleteTags">
      <template #empty>
        <empty-tags-state :no-containers-image="config.noContainersImage" />
      </template>
      <template #loader>
        <tags-loader v-once />
      </template>
    </tags-table>

    <gl-pagination
      v-if="!isLoading"
      ref="pagination"
      v-model="currentPage"
      :per-page="tagsPagination.perPage"
      :total-items="tagsPagination.total"
      align="center"
      class="w-100"
    />

    <delete-modal
      ref="deleteModal"
      :items-to-be-deleted="itemsToBeDeleted"
      @confirmDelete="onDeletionConfirmed"
      @cancel="track('cancel_delete')"
    />
  </div>
</template>
