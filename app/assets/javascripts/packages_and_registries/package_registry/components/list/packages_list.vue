<script>
import { GlAlert, GlButton } from '@gitlab/ui';
import { s__, sprintf, n__ } from '~/locale';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import PackagesListRow from '~/packages_and_registries/package_registry/components/list/package_list_row.vue';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import DeleteModal from '~/packages_and_registries/package_registry/components/delete_modal.vue';
import {
  DELETE_PACKAGE_TRACKING_ACTION,
  DELETE_PACKAGES_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGE_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGES_TRACKING_ACTION,
  CANCEL_DELETE_PACKAGE_TRACKING_ACTION,
  CANCEL_DELETE_PACKAGES_TRACKING_ACTION,
  PACKAGE_ERROR_STATUS,
  PACKAGE_TYPE_MAVEN,
  PACKAGE_TYPE_NPM,
  PACKAGE_TYPE_PYPI,
} from '~/packages_and_registries/package_registry/constants';
import { packageTypeToTrackCategory } from '~/packages_and_registries/package_registry/utils';
import Tracking from '~/tracking';

const forwardingFieldToPackageTypeMapping = {
  mavenPackageRequestsForwarding: PACKAGE_TYPE_MAVEN,
  npmPackageRequestsForwarding: PACKAGE_TYPE_NPM,
  pypiPackageRequestsForwarding: PACKAGE_TYPE_PYPI,
};

export default {
  name: 'PackagesList',
  components: {
    GlAlert,
    GlButton,
    DeleteModal,
    PackagesListLoader,
    PackagesListRow,
    RegistryList,
  },
  mixins: [Tracking.mixin()],
  inject: ['canDeletePackages'],
  props: {
    list: {
      type: Array,
      required: false,
      default: () => [],
    },
    hideErrorAlert: {
      type: Boolean,
      required: false,
      default: false,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    groupSettings: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },

  data() {
    return {
      itemsToBeDeleted: [],
      errorPackages: [],
    };
  },
  computed: {
    itemToBeDeleted() {
      if (this.itemsToBeDeleted.length === 1) {
        const [itemToBeDeleted] = this.itemsToBeDeleted;
        return itemToBeDeleted;
      }
      return null;
    },
    listTitle() {
      return n__('%d package', '%d packages', this.list.length);
    },
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
      if (this.singleErrorPackage) {
        return sprintf(
          s__('PackageRegistry|There was an error publishing a %{packageName} package'),
          { packageName: this.singleErrorPackage.name },
        );
      }
      return sprintf(s__('PackageRegistry|There was an error publishing %{count} packages'), {
        count: this.errorPackages.length,
      });
    },
    errorMessageBodyAlert() {
      if (this.singleErrorPackage) {
        return this.singleErrorPackage.statusMessage || this.$options.i18n.errorMessageBodyAlert;
      }

      return sprintf(
        s__(
          'PackageRegistry|%{count} packages were not published to the registry. Remove these packages and try again.',
        ),
        {
          count: this.errorPackages.length,
        },
      );
    },
    singleErrorPackage() {
      if (this.errorPackages.length === 1) {
        const [errorPackage] = this.errorPackages;
        return errorPackage;
      }

      return null;
    },
    showErrorPackageAlert() {
      return this.errorPackages.length > 0 && !this.hideErrorAlert;
    },
    errorPackagesHref() {
      // For reactivity we depend on showErrorPackageAlert so we update accordingly
      if (!this.showErrorPackageAlert) {
        return '';
      }

      const pageParams = { after: null, before: null };
      return mergeUrlParams({ status: 'error', ...pageParams }, window.location.href);
    },
    packageTypesWithForwardingEnabled() {
      return Object.keys(this.groupSettings)
        .filter((field) => this.groupSettings[field])
        .map((field) => forwardingFieldToPackageTypeMapping[field]);
    },
    isRequestForwardingEnabled() {
      const selectedPackageTypes = new Set(this.itemsToBeDeleted.map((item) => item.packageType));
      return this.packageTypesWithForwardingEnabled.some((type) => selectedPackageTypes.has(type));
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
    setItemsToBeDeleted(items) {
      this.itemsToBeDeleted = items;
      if (items.length === 1) {
        this.track(REQUEST_DELETE_PACKAGE_TRACKING_ACTION);
      } else {
        this.track(REQUEST_DELETE_PACKAGES_TRACKING_ACTION);
      }
      this.$refs.deletePackagesModal.show();
    },
    deleteItemsConfirmation() {
      this.$emit('delete', this.itemsToBeDeleted);

      if (this.itemToBeDeleted) {
        this.track(DELETE_PACKAGE_TRACKING_ACTION);
      } else {
        this.track(DELETE_PACKAGES_TRACKING_ACTION);
      }

      this.itemsToBeDeleted = [];
    },
    deleteItemsCanceled() {
      if (this.itemToBeDeleted) {
        this.track(CANCEL_DELETE_PACKAGE_TRACKING_ACTION);
      } else {
        this.track(CANCEL_DELETE_PACKAGES_TRACKING_ACTION);
      }
      this.itemsToBeDeleted = [];
    },
    showConfirmationModal() {
      this.setItemsToBeDeleted([this.singleErrorPackage]);
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
        class="gl-mt-5"
        variant="danger"
        :title="errorTitleAlert"
      >
        {{ errorMessageBodyAlert }}
        <template #actions>
          <gl-button v-if="singleErrorPackage" variant="confirm" @click="showConfirmationModal">{{
            $options.i18n.deleteThisPackage
          }}</gl-button>
          <gl-button v-else :href="errorPackagesHref" variant="confirm">{{
            s__('PackageRegistry|Show packages with errors')
          }}</gl-button>
        </template>
      </gl-alert>
      <registry-list
        data-testid="packages-table"
        :hidden-delete="!canDeletePackages"
        :is-loading="isLoading"
        :items="list"
        :title="listTitle"
        @delete="setItemsToBeDeleted"
      >
        <template #default="{ selectItem, isSelected, item, first }">
          <packages-list-row
            :first="first"
            :package-entity="item"
            :selected="isSelected(item)"
            @delete="setItemsToBeDeleted([item])"
            @select="selectItem(item)"
          />
        </template>
      </registry-list>

      <delete-modal
        ref="deletePackagesModal"
        :items-to-be-deleted="itemsToBeDeleted"
        :show-request-forwarding-content="isRequestForwardingEnabled"
        @confirm="deleteItemsConfirmation"
        @cancel="deleteItemsCanceled"
      />
    </template>
  </div>
</template>
