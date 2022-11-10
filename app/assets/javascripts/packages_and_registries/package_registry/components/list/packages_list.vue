<script>
import { GlAlert } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import DeletePackageModal from '~/packages_and_registries/shared/components/delete_package_modal.vue';
import PackagesListRow from '~/packages_and_registries/package_registry/components/list/package_list_row.vue';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import {
  DELETE_PACKAGE_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGE_TRACKING_ACTION,
  CANCEL_DELETE_PACKAGE_TRACKING_ACTION,
  PACKAGE_ERROR_STATUS,
} from '~/packages_and_registries/package_registry/constants';
import { packageTypeToTrackCategory } from '~/packages_and_registries/package_registry/utils';
import Tracking from '~/tracking';

export default {
  name: 'PackagesList',
  components: {
    GlAlert,
    DeletePackageModal,
    PackagesListLoader,
    PackagesListRow,
    RegistryList,
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
      errorPackages: [],
    };
  },
  computed: {
    isListEmpty() {
      return !this.list || this.list.length === 0;
    },
    tracking() {
      const category = this.itemToBeDeleted
        ? packageTypeToTrackCategory(this.itemToBeDeleted.packageType)
        : undefined;
      return {
        category,
      };
    },
    errorTitleAlert() {
      return sprintf(
        s__('PackageRegistry|There was an error publishing a %{packageName} package'),
        { packageName: this.errorPackages[0].name },
      );
    },
    showErrorPackageAlert() {
      return this.errorPackages.length > 0;
    },
  },
  watch: {
    list(newVal) {
      this.errorPackages = newVal.filter((pkg) => pkg.status === PACKAGE_ERROR_STATUS);
    },
  },
  created() {
    this.errorPackages =
      this.list.length > 0 ? this.list.filter((pkg) => pkg.status === PACKAGE_ERROR_STATUS) : [];
  },
  methods: {
    setItemToBeDeleted(item) {
      this.itemToBeDeleted = { ...item };
      this.track(REQUEST_DELETE_PACKAGE_TRACKING_ACTION);
    },
    deleteItemConfirmation() {
      this.$emit('package:delete', this.itemToBeDeleted);
      this.track(DELETE_PACKAGE_TRACKING_ACTION);
      this.itemToBeDeleted = null;
    },
    deleteItemCanceled() {
      this.track(CANCEL_DELETE_PACKAGE_TRACKING_ACTION);
      this.itemToBeDeleted = null;
    },
    showConfirmationModal() {
      this.setItemToBeDeleted(this.errorPackages[0]);
    },
  },
  i18n: {
    errorMessageBodyAlert: s__(
      'PackageRegistry|There was a timeout and the package was not published. Delete this package and try again.',
    ),
    deleteThisPackage: s__('PackageRegistry|Delete this package'),
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
      <gl-alert
        v-if="showErrorPackageAlert"
        variant="danger"
        :title="errorTitleAlert"
        :primary-button-text="$options.i18n.deleteThisPackage"
        @primaryAction="showConfirmationModal"
        >{{ $options.i18n.errorMessageBodyAlert }}</gl-alert
      >
      <registry-list
        data-testid="packages-table"
        :hidden-delete="true"
        :is-loading="isLoading"
        :items="list"
        :pagination="pageInfo"
        @prev-page="$emit('prev-page')"
        @next-page="$emit('next-page')"
      >
        <template #default="{ item }">
          <packages-list-row :package-entity="item" @packageToDelete="setItemToBeDeleted(item)" />
        </template>
      </registry-list>

      <delete-package-modal
        :item-to-be-deleted="itemToBeDeleted"
        @ok="deleteItemConfirmation"
        @cancel="deleteItemCanceled"
      />
    </template>
  </div>
</template>
