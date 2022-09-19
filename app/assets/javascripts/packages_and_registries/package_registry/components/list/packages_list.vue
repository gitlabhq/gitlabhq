<script>
import { GlAlert, GlModal, GlSprintf, GlKeysetPagination } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import PackagesListRow from '~/packages_and_registries/package_registry/components/list/package_list_row.vue';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import {
  DELETE_PACKAGE_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGE_TRACKING_ACTION,
  CANCEL_DELETE_PACKAGE_TRACKING_ACTION,
  PACKAGE_ERROR_STATUS,
} from '~/packages_and_registries/package_registry/constants';
import { packageTypeToTrackCategory } from '~/packages_and_registries/package_registry/utils';
import Tracking from '~/tracking';

export default {
  components: {
    GlAlert,
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
      errorPackages: [],
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
    deleteModalActionPrimaryProps() {
      return {
        text: this.$options.i18n.modalAction,
        attributes: {
          variant: 'danger',
        },
      };
    },
    deleteModalActionCancelProps() {
      return {
        text: __('Cancel'),
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
    },
    deleteItemCanceled() {
      this.track(CANCEL_DELETE_PACKAGE_TRACKING_ACTION);
    },
    showConfirmationModal() {
      this.setItemToBeDeleted(this.errorPackages[0]);
    },
  },
  i18n: {
    deleteModalContent: s__(
      'PackageRegistry|You are about to delete %{name}, this operation is irreversible, are you sure?',
    ),
    modalAction: s__('PackageRegistry|Delete package'),
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
      <div data-testid="packages-table">
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
        size="sm"
        :action-primary="deleteModalActionPrimaryProps"
        :action-cancel="deleteModalActionCancelProps"
        @ok="deleteItemConfirmation"
        @cancel="deleteItemCanceled"
      >
        <template #modal-title>{{ $options.i18n.modalAction }}</template>
        <gl-sprintf :message="$options.i18n.deleteModalContent">
          <template #name>
            <strong>{{ deletePackageName }}</strong>
          </template>
        </gl-sprintf>
      </gl-modal>
    </template>
  </div>
</template>
