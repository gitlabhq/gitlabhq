<script>
import { n__ } from '~/locale';
import VersionRow from '~/packages_and_registries/package_registry/components/details/version_row.vue';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import DeleteModal from '~/packages_and_registries/package_registry/components/delete_modal.vue';
import {
  CANCEL_DELETE_PACKAGE_VERSIONS_TRACKING_ACTION,
  DELETE_PACKAGE_VERSIONS_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGE_VERSIONS_TRACKING_ACTION,
} from '~/packages_and_registries/package_registry/constants';
import Tracking from '~/tracking';

export default {
  components: {
    DeleteModal,
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
  },
  methods: {
    deleteItemsCanceled() {
      this.track(CANCEL_DELETE_PACKAGE_VERSIONS_TRACKING_ACTION);
      this.itemsToBeDeleted = [];
    },
    deleteItemsConfirmation() {
      this.$emit('delete', this.itemsToBeDeleted);
      this.track(DELETE_PACKAGE_VERSIONS_TRACKING_ACTION);
      this.itemsToBeDeleted = [];
    },
    setItemsToBeDeleted(items) {
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
            @select="selectItem(item)"
          />
        </template>
      </registry-list>

      <delete-modal
        ref="deletePackagesModal"
        :items-to-be-deleted="itemsToBeDeleted"
        @confirm="deleteItemsConfirmation"
        @cancel="deleteItemsCanceled"
      />
    </div>
  </div>
</template>
