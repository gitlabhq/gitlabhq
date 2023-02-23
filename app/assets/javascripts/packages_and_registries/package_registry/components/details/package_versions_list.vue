<script>
import { n__ } from '~/locale';
import VersionRow from '~/packages_and_registries/package_registry/components/details/version_row.vue';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import DeleteModal from '~/packages_and_registries/package_registry/components/delete_modal.vue';
import DeletePackageModal from '~/packages_and_registries/shared/components/delete_package_modal.vue';
import {
  CANCEL_DELETE_PACKAGE_VERSION_TRACKING_ACTION,
  CANCEL_DELETE_PACKAGE_VERSIONS_TRACKING_ACTION,
  DELETE_PACKAGE_VERSION_TRACKING_ACTION,
  DELETE_PACKAGE_VERSIONS_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGE_VERSION_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGE_VERSIONS_TRACKING_ACTION,
} from '~/packages_and_registries/package_registry/constants';
import Tracking from '~/tracking';
import { packageTypeToTrackCategory } from '~/packages_and_registries/package_registry/utils';

export default {
  components: {
    DeleteModal,
    DeletePackageModal,
    VersionRow,
    PackagesListLoader,
    RegistryList,
  },
  mixins: [Tracking.mixin()],
  props: {
    canDestroy: {
      type: Boolean,
      required: false,
      default: false,
    },
    versions: {
      type: Array,
      required: true,
      default: () => [],
    },
    pageInfo: {
      type: Object,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      itemToBeDeleted: null,
      itemsToBeDeleted: [],
    };
  },
  computed: {
    listTitle() {
      return n__('%d version', '%d versions', this.versions.length);
    },
    isListEmpty() {
      return this.versions.length === 0;
    },
    tracking() {
      const category = this.itemToBeDeleted
        ? packageTypeToTrackCategory(this.itemToBeDeleted.packageType)
        : undefined;
      return {
        category,
      };
    },
  },
  methods: {
    deleteItemConfirmation() {
      this.$emit('delete', [this.itemToBeDeleted]);
      this.track(DELETE_PACKAGE_VERSION_TRACKING_ACTION);
      this.itemToBeDeleted = null;
    },
    deleteItemCanceled() {
      this.track(CANCEL_DELETE_PACKAGE_VERSION_TRACKING_ACTION);
      this.itemToBeDeleted = null;
    },
    deleteItemsCanceled() {
      this.track(CANCEL_DELETE_PACKAGE_VERSIONS_TRACKING_ACTION);
      this.itemsToBeDeleted = [];
    },
    deleteItemsConfirmation() {
      this.$emit('delete', this.itemsToBeDeleted);
      this.track(DELETE_PACKAGE_VERSIONS_TRACKING_ACTION);
      this.itemsToBeDeleted = [];
    },
    setItemToBeDeleted(item) {
      this.itemToBeDeleted = { ...item };
      this.track(REQUEST_DELETE_PACKAGE_VERSION_TRACKING_ACTION);
    },
    setItemsToBeDeleted(items) {
      if (items.length === 1) {
        const [item] = items;
        this.setItemToBeDeleted(item);
        return;
      }
      this.itemsToBeDeleted = items;
      this.track(REQUEST_DELETE_PACKAGE_VERSIONS_TRACKING_ACTION);
      this.$refs.deletePackagesModal.show();
    },
  },
};
</script>
<template>
  <div>
    <div v-if="isLoading">
      <packages-list-loader />
    </div>
    <slot v-else-if="isListEmpty" name="empty-state"></slot>
    <div v-else>
      <registry-list
        :hidden-delete="!canDestroy"
        :is-loading="isLoading"
        :items="versions"
        :pagination="pageInfo"
        :title="listTitle"
        @delete="setItemsToBeDeleted"
        @prev-page="$emit('prev-page')"
        @next-page="$emit('next-page')"
      >
        <template #default="{ first, item, isSelected, selectItem }">
          <!-- `first` prop is used to decide whether to show the top border
          for the first element. We want to show the top border only when
          user has permission to bulk delete versions. -->
          <version-row
            :first="canDestroy && first"
            :package-entity="item"
            :selected="isSelected(item)"
            @delete="setItemToBeDeleted(item)"
            @select="selectItem(item)"
          />
        </template>
      </registry-list>

      <delete-package-modal
        :item-to-be-deleted="itemToBeDeleted"
        @ok="deleteItemConfirmation"
        @cancel="deleteItemCanceled"
      />

      <delete-modal
        ref="deletePackagesModal"
        :items-to-be-deleted="itemsToBeDeleted"
        @confirm="deleteItemsConfirmation"
        @cancel="deleteItemsCanceled"
      />
    </div>
  </div>
</template>
