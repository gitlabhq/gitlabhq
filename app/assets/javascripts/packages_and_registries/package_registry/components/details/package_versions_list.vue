<script>
import { GlAlert } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { n__ } from '~/locale';
import VersionRow from '~/packages_and_registries/package_registry/components/details/version_row.vue';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import DeleteModal from '~/packages_and_registries/package_registry/components/delete_modal.vue';
import {
  CANCEL_DELETE_PACKAGE_VERSION_TRACKING_ACTION,
  CANCEL_DELETE_PACKAGE_VERSIONS_TRACKING_ACTION,
  DELETE_PACKAGE_VERSION_TRACKING_ACTION,
  DELETE_PACKAGE_VERSIONS_TRACKING_ACTION,
  FETCH_PACKAGE_VERSIONS_ERROR_MESSAGE,
  GRAPHQL_PAGE_SIZE,
  REQUEST_DELETE_PACKAGE_VERSION_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGE_VERSIONS_TRACKING_ACTION,
} from '~/packages_and_registries/package_registry/constants';
import Tracking from '~/tracking';
import { packageTypeToTrackCategory } from '~/packages_and_registries/package_registry/utils';
import getPackageVersionsQuery from '~/packages_and_registries/package_registry/graphql/queries/get_package_versions.query.graphql';

export default {
  components: {
    DeleteModal,
    GlAlert,
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
    count: {
      type: Number,
      required: false,
      default: 0,
    },
    isMutationLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    isRequestForwardingEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    packageId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      itemsToBeDeleted: [],
      packageVersions: {},
      fetchPackageVersionsError: false,
    };
  },
  apollo: {
    packageVersions: {
      query: getPackageVersionsQuery,
      variables() {
        return this.queryVariables;
      },
      skip() {
        return this.isListEmpty;
      },
      update(data) {
        return data.package?.versions ?? {};
      },
      error(error) {
        this.fetchPackageVersionsError = true;
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    itemToBeDeleted() {
      return this.itemsToBeDeleted.length === 1 ? this.itemsToBeDeleted[0] : null;
    },
    isListEmpty() {
      return this.count === 0;
    },
    isLoading() {
      return this.$apollo.queries.packageVersions.loading || this.isMutationLoading;
    },
    pageInfo() {
      return this.packageVersions?.pageInfo ?? {};
    },
    listTitle() {
      return n__('%d version', '%d versions', this.versions.length);
    },
    queryVariables() {
      return {
        id: this.packageId,
        first: GRAPHQL_PAGE_SIZE,
      };
    },
    tracking() {
      const category = this.itemToBeDeleted
        ? packageTypeToTrackCategory(this.itemToBeDeleted.packageType)
        : undefined;
      return {
        category,
      };
    },
    versions() {
      return this.packageVersions?.nodes ?? [];
    },
  },
  methods: {
    deleteItemsCanceled() {
      if (this.itemToBeDeleted) {
        this.track(CANCEL_DELETE_PACKAGE_VERSION_TRACKING_ACTION);
      } else {
        this.track(CANCEL_DELETE_PACKAGE_VERSIONS_TRACKING_ACTION);
      }

      this.itemsToBeDeleted = [];
    },
    deleteItemsConfirmation() {
      this.$emit('delete', this.itemsToBeDeleted);
      if (this.itemToBeDeleted) {
        this.track(DELETE_PACKAGE_VERSION_TRACKING_ACTION);
      } else {
        this.track(DELETE_PACKAGE_VERSIONS_TRACKING_ACTION);
      }
      this.itemsToBeDeleted = [];
    },
    setItemsToBeDeleted(items) {
      this.itemsToBeDeleted = items;
      if (items.length === 1) {
        this.track(REQUEST_DELETE_PACKAGE_VERSION_TRACKING_ACTION);
      } else {
        this.track(REQUEST_DELETE_PACKAGE_VERSIONS_TRACKING_ACTION);
      }
      this.$refs.deletePackagesModal.show();
    },
    fetchPreviousVersionsPage() {
      const variables = {
        ...this.queryVariables,
        first: null,
        last: GRAPHQL_PAGE_SIZE,
        before: this.pageInfo?.startCursor,
      };
      this.$apollo.queries.packageVersions.fetchMore({
        variables,
      });
    },
    fetchNextVersionsPage() {
      const variables = {
        ...this.queryVariables,
        first: GRAPHQL_PAGE_SIZE,
        last: null,
        after: this.pageInfo?.endCursor,
      };

      this.$apollo.queries.packageVersions.fetchMore({
        variables,
      });
    },
  },
  i18n: {
    errorMessage: FETCH_PACKAGE_VERSIONS_ERROR_MESSAGE,
  },
};
</script>
<template>
  <div>
    <div v-if="isLoading">
      <packages-list-loader />
    </div>
    <gl-alert v-else-if="fetchPackageVersionsError" variant="danger" :dismissible="false">{{
      $options.i18n.errorMessage
    }}</gl-alert>
    <slot v-else-if="isListEmpty" name="empty-state"></slot>
    <div v-else>
      <registry-list
        :hidden-delete="!canDestroy"
        :is-loading="isLoading"
        :items="versions"
        :pagination="pageInfo"
        :title="listTitle"
        @delete="setItemsToBeDeleted"
        @prev-page="fetchPreviousVersionsPage"
        @next-page="fetchNextVersionsPage"
      >
        <template #default="{ first, item, isSelected, selectItem }">
          <version-row
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
    </div>
  </div>
</template>
