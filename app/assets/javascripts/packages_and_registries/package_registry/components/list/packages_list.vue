<script>
import { GlModal, GlSprintf, GlKeysetPagination } from '@gitlab/ui';
import { s__ } from '~/locale';
import PackagesListRow from '~/packages_and_registries/package_registry/components/list/package_list_row.vue';
import PackagesListLoader from '~/packages/shared/components/packages_list_loader.vue';
import {
  DELETE_PACKAGE_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGE_TRACKING_ACTION,
  CANCEL_DELETE_PACKAGE_TRACKING_ACTION,
} from '~/packages_and_registries/package_registry/constants';
import { packageTypeToTrackCategory } from '~/packages_and_registries/package_registry/utils';
import Tracking from '~/tracking';

export default {
  components: {
    GlKeysetPagination,
    GlModal,
    GlSprintf,
    PackagesListLoader,
    PackagesListRow,
  },
  mixins: [Tracking.mixin()],
  props: {
    list: {
      type: Array,
      required: false,
      default: () => [],
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    pageInfo: {
      type: Object,
      required: true,
    },
  },

  data() {
    return {
      itemToBeDeleted: null,
    };
  },
  computed: {
    isListEmpty() {
      return !this.list || this.list.length === 0;
    },
    deletePackageName() {
      return this.itemToBeDeleted?.name ?? '';
    },
    tracking() {
      const category = this.itemToBeDeleted
        ? packageTypeToTrackCategory(this.itemToBeDeleted.packageType)
        : undefined;
      return {
        category,
      };
    },
    showPagination() {
      return this.pageInfo.hasPreviousPage || this.pageInfo.hasNextPage;
    },
    showDeleteModal: {
      get() {
        return Boolean(this.itemToBeDeleted);
      },
      set(value) {
        if (!value) {
          this.itemToBeDeleted = null;
        }
      },
    },
  },
  methods: {
    setItemToBeDeleted(item) {
      this.itemToBeDeleted = { ...item };
      this.track(REQUEST_DELETE_PACKAGE_TRACKING_ACTION);
    },
    deleteItemConfirmation() {
      this.$emit('package:delete', this.itemToBeDeleted);
      this.track(DELETE_PACKAGE_TRACKING_ACTION);
    },
    deleteItemCanceled() {
      this.track(CANCEL_DELETE_PACKAGE_TRACKING_ACTION);
    },
  },
  i18n: {
    deleteModalContent: s__(
      'PackageRegistry|You are about to delete %{name}, this operation is irreversible, are you sure?',
    ),
    modalAction: s__('PackageRegistry|Delete package'),
  },
};
</script>

<template>
  <div class="gl-display-flex gl-flex-direction-column">
    <slot v-if="isListEmpty && !isLoading" name="empty-state"></slot>

    <div v-else-if="isLoading">
      <packages-list-loader />
    </div>

    <template v-else>
      <div data-qa-selector="packages-table">
        <packages-list-row
          v-for="packageEntity in list"
          :key="packageEntity.id"
          :package-entity="packageEntity"
          @packageToDelete="setItemToBeDeleted"
        />
      </div>

      <div class="gl-display-flex gl-justify-content-center">
        <gl-keyset-pagination
          v-if="showPagination"
          v-bind="pageInfo"
          class="gl-mt-3"
          @prev="$emit('prev-page')"
          @next="$emit('next-page')"
        />
      </div>

      <gl-modal
        v-model="showDeleteModal"
        modal-id="confirm-delete-pacakge"
        ok-variant="danger"
        @ok="deleteItemConfirmation"
        @cancel="deleteItemCanceled"
      >
        <template #modal-title>{{ $options.i18n.modalAction }}</template>
        <template #modal-ok>{{ $options.i18n.modalAction }}</template>
        <gl-sprintf :message="$options.i18n.deleteModalContent">
          <template #name>
            <strong>{{ deletePackageName }}</strong>
          </template>
        </gl-sprintf>
      </gl-modal>
    </template>
  </div>
</template>
