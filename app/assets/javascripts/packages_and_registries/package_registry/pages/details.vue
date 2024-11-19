<script>
import {
  GlAlert,
  GlBadge,
  GlButton,
  GlLink,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
  GlEmptyState,
  GlTab,
  GlTabs,
  GlSprintf,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { TYPENAME_PACKAGES_PACKAGE } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { objectToQuery } from '~/lib/utils/url_utility';
import { s__, __ } from '~/locale';
import { packageTypeToTrackCategory } from '~/packages_and_registries/package_registry/utils';
import AdditionalMetadata from '~/packages_and_registries/package_registry/components/details/additional_metadata.vue';
import DependencyRow from '~/packages_and_registries/package_registry/components/details/dependency_row.vue';
import InstallationCommands from '~/packages_and_registries/package_registry/components/details/installation_commands.vue';
import PackageHistory from '~/packages_and_registries/package_registry/components/details/package_history.vue';
import PackageTitle from '~/packages_and_registries/package_registry/components/details/package_title.vue';
import DeletePackages from '~/packages_and_registries/package_registry/components/functional/delete_packages.vue';
import {
  PACKAGE_DEPRECATED_STATUS,
  PACKAGE_TYPE_NUGET,
  PACKAGE_TYPE_COMPOSER,
  PACKAGE_TYPE_CONAN,
  PACKAGE_TYPE_MAVEN,
  PACKAGE_TYPE_PYPI,
  PACKAGE_TYPE_NPM,
  DELETE_PACKAGE_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGE_TRACKING_ACTION,
  CANCEL_DELETE_PACKAGE_TRACKING_ACTION,
  REQUEST_FORWARDING_HELP_PAGE_PATH,
  SHOW_DELETE_SUCCESS_ALERT,
  FETCH_PACKAGE_DETAILS_ERROR_MESSAGE,
  DELETE_PACKAGE_REQUEST_FORWARDING_MODAL_CONTENT,
  DELETE_MODAL_TITLE,
  DELETE_MODAL_CONTENT,
  GRAPHQL_PAGE_SIZE,
} from '~/packages_and_registries/package_registry/constants';

import getPackageDetails from '~/packages_and_registries/package_registry/graphql/queries/get_package_details.query.graphql';
import getGroupPackageSettings from '~/packages_and_registries/package_registry/graphql/queries/get_group_package_settings.query.graphql';
import getPackageVersionsQuery from '~/packages_and_registries/package_registry/graphql/queries/get_package_versions.query.graphql';

import * as Sentry from '~/sentry/sentry_browser_wrapper';
import Tracking from '~/tracking';

export default {
  name: 'PackagesApp',
  components: {
    GlAlert,
    GlBadge,
    GlButton,
    GlEmptyState,
    GlModal,
    GlLink,
    GlTab,
    GlTabs,
    GlSprintf,
    PackageTitle,
    DependencyRow,
    PackageHistory,
    AdditionalMetadata,
    InstallationCommands,
    PackageFiles: () =>
      import('~/packages_and_registries/package_registry/components/details/package_files.vue'),
    DeletePackages,
    PackageVersionsList: () =>
      import(
        '~/packages_and_registries/package_registry/components/details/package_versions_list.vue'
      ),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  mixins: [Tracking.mixin()],
  inject: ['emptyListIllustration', 'projectListUrl', 'groupListUrl', 'breadCrumbState'],
  trackingActions: {
    DELETE_PACKAGE_TRACKING_ACTION,
    REQUEST_DELETE_PACKAGE_TRACKING_ACTION,
    CANCEL_DELETE_PACKAGE_TRACKING_ACTION,
  },
  data() {
    return {
      deletePackageModalContent: DELETE_MODAL_CONTENT,
      filesToDelete: [],
      mutationLoading: false,
      versionsMutationLoading: false,
      packageEntity: {},
      groupSettings: {},
    };
  },
  apollo: {
    packageEntity: {
      query: getPackageDetails,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.package || {};
      },
      error(error) {
        createAlert({
          message: FETCH_PACKAGE_DETAILS_ERROR_MESSAGE,
          captureError: true,
          error,
        });
      },
      result() {
        this.breadCrumbState.updateName(
          `${this.packageEntity?.name} v${this.packageEntity?.version}`,
        );
      },
    },
    groupSettings: {
      query: getGroupPackageSettings,
      variables() {
        return {
          fullPath: this.projectPath,
        };
      },
      update(data) {
        return data.project?.group?.packageSettings || {};
      },
      skip() {
        return !(this.isRequestForwardingSupported && this.canDelete);
      },
      error(error) {
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    canDelete() {
      return this.packageEntity.userPermissions?.destroyPackage;
    },
    deleteModalContent() {
      return this.isRequestForwardingEnabled
        ? DELETE_PACKAGE_REQUEST_FORWARDING_MODAL_CONTENT
        : this.deletePackageModalContent;
    },
    projectName() {
      return this.packageEntity.project?.name;
    },
    projectPath() {
      return this.packageEntity.project?.fullPath;
    },
    packageId() {
      return this.$route.params.id;
    },
    queryVariables() {
      return {
        id: convertToGraphQLId(TYPENAME_PACKAGES_PACKAGE, this.packageId),
      };
    },
    packageType() {
      return this.packageEntity.packageType;
    },
    isLoading() {
      return this.$apollo.queries.packageEntity.loading;
    },
    isRequestForwardingSupported() {
      return [PACKAGE_TYPE_MAVEN, PACKAGE_TYPE_PYPI, PACKAGE_TYPE_NPM].includes(this.packageType);
    },
    isRequestForwardingEnabled() {
      return (
        this.isRequestForwardingSupported &&
        this.groupSettings[`${this.packageType.toLowerCase()}PackageRequestsForwarding`]
      );
    },
    isValidPackage() {
      return this.isLoading || Boolean(this.packageEntity.name);
    },
    tracking() {
      return {
        category: packageTypeToTrackCategory(this.packageType),
      };
    },
    packageDependencies() {
      return this.packageEntity.dependencyLinks?.nodes || [];
    },
    packageVersionsCount() {
      return this.packageEntity.versions?.count ?? 0;
    },
    showDependencies() {
      return this.packageType === PACKAGE_TYPE_NUGET;
    },
    showDeprecationAlert() {
      return this.packageEntity.status === PACKAGE_DEPRECATED_STATUS;
    },
    showFiles() {
      return this.packageType !== PACKAGE_TYPE_COMPOSER;
    },
    showMetadata() {
      return [
        PACKAGE_TYPE_COMPOSER,
        PACKAGE_TYPE_CONAN,
        PACKAGE_TYPE_MAVEN,
        PACKAGE_TYPE_NUGET,
        PACKAGE_TYPE_PYPI,
      ].includes(this.packageType);
    },
    refetchVersionsQueryData() {
      return [
        {
          query: getPackageVersionsQuery,
          variables: {
            id: this.queryVariables.id,
            first: GRAPHQL_PAGE_SIZE,
          },
        },
      ];
    },
  },
  methods: {
    formatSize(size) {
      return numberToHumanSize(size);
    },
    navigateToListWithSuccessModal() {
      const returnTo =
        !this.groupListUrl || document.referrer.includes(this.projectName)
          ? this.projectListUrl
          : this.groupListUrl; // to avoid security issue url are supplied from backend

      const modalQuery = objectToQuery({ [SHOW_DELETE_SUCCESS_ALERT]: true });

      window.location.replace(`${returnTo}?${modalQuery}`);
    },
    handleAllFilesDelete(content) {
      this.deletePackageModalContent = content;
      this.$refs.deleteModal.show();
    },
    resetDeleteModalContent() {
      this.deletePackageModalContent = DELETE_MODAL_CONTENT;
    },
  },
  i18n: {
    DELETE_MODAL_TITLE,
    otherVersionsTabTitle: s__('PackageRegistry|Other versions'),
  },
  links: {
    REQUEST_FORWARDING_HELP_PAGE_PATH,
  },
  modal: {
    packageDeletePrimaryAction: {
      text: s__('PackageRegistry|Permanently delete'),
      attributes: {
        variant: 'danger',
        category: 'primary',
        'data-testid': 'delete-modal-button',
      },
    },
    fileDeletePrimaryAction: {
      text: __('Delete'),
      attributes: { variant: 'danger', category: 'primary' },
    },
    filesDeletePrimaryAction: {
      text: s__('PackageRegistry|Permanently delete assets'),
      attributes: { variant: 'danger', category: 'primary' },
    },
    cancelAction: {
      text: __('Cancel'),
    },
  },
};
</script>

<template>
  <gl-empty-state
    v-if="!isValidPackage"
    :title="s__('PackageRegistry|Unable to load package')"
    :description="s__('PackageRegistry|There was a problem fetching the details for this package.')"
    :svg-path="emptyListIllustration"
    :svg-height="null"
  />
  <div v-else-if="projectName" class="packages-app">
    <package-title :package-entity="packageEntity">
      <template #delete-button>
        <gl-button
          v-if="canDelete"
          v-gl-modal="'delete-modal'"
          variant="danger"
          category="primary"
          data-testid="delete-package"
        >
          {{ __('Delete') }}
        </gl-button>
      </template>
    </package-title>

    <gl-tabs>
      <gl-tab :title="__('Detail')">
        <div data-testid="package-information-content">
          <package-history :package-entity="packageEntity" :project-name="projectName" />

          <gl-alert v-if="showDeprecationAlert" :dismissible="false" variant="warning">
            {{ s__('PackageRegistry|This package version has been deprecated.') }}
          </gl-alert>
          <installation-commands :package-entity="packageEntity" />

          <additional-metadata
            v-if="showMetadata"
            :package-id="packageEntity.id"
            :package-type="packageType"
          />

          <package-files
            v-if="showFiles"
            :can-delete="canDelete"
            :package-id="packageEntity.id"
            :package-type="packageType"
            :project-path="projectPath"
            @delete-all-files="handleAllFilesDelete"
          />
        </div>
      </gl-tab>

      <gl-tab v-if="showDependencies">
        <template #title>
          <span>{{ __('Dependencies') }}</span>
          <gl-badge data-testid="dependencies-badge">{{ packageDependencies.length }}</gl-badge>
        </template>

        <template v-if="packageDependencies.length > 0">
          <dependency-row v-for="dep in packageDependencies" :key="dep.id" :dependency-link="dep" />
        </template>

        <p v-else class="gl-mt-3" data-testid="no-dependencies-message">
          {{ s__('PackageRegistry|This NuGet package has no dependencies.') }}
        </p>
      </gl-tab>

      <gl-tab title-item-class="js-versions-tab" lazy>
        <template #title>
          <span>{{ $options.i18n.otherVersionsTabTitle }}</span>
          <gl-badge class="gl-tab-counter-badge" data-testid="other-versions-badge">{{
            packageVersionsCount
          }}</gl-badge>
        </template>

        <delete-packages
          :refetch-queries="refetchVersionsQueryData"
          show-success-alert
          @start="versionsMutationLoading = true"
          @end="versionsMutationLoading = false"
        >
          <template #default="{ deletePackages }">
            <package-versions-list
              :can-destroy="packageEntity.userPermissions.destroyPackage"
              :count="packageVersionsCount"
              :is-mutation-loading="versionsMutationLoading"
              :is-request-forwarding-enabled="isRequestForwardingEnabled"
              :package-id="packageEntity.id"
              @delete="deletePackages"
            >
              <template #empty-state>
                <p class="gl-mt-3" data-testid="no-versions-message">
                  {{ s__('PackageRegistry|There are no other versions of this package.') }}
                </p>
              </template>
            </package-versions-list>
          </template>
        </delete-packages>
      </gl-tab>
    </gl-tabs>

    <delete-packages
      @start="track($options.trackingActions.DELETE_PACKAGE_TRACKING_ACTION)"
      @end="navigateToListWithSuccessModal"
    >
      <template #default="{ deletePackages }">
        <gl-modal
          ref="deleteModal"
          size="sm"
          modal-id="delete-modal"
          data-testid="delete-modal"
          :action-primary="$options.modal.packageDeletePrimaryAction"
          :action-cancel="$options.modal.cancelAction"
          @primary="deletePackages([packageEntity])"
          @hidden="resetDeleteModalContent"
          @canceled="track($options.trackingActions.CANCEL_DELETE_PACKAGE)"
        >
          <template #modal-title>{{ $options.i18n.DELETE_MODAL_TITLE }}</template>
          <p>
            <gl-sprintf :message="deleteModalContent">
              <template v-if="isRequestForwardingEnabled" #docLink="{ content }">
                <gl-link :href="$options.links.REQUEST_FORWARDING_HELP_PAGE_PATH">{{
                  content
                }}</gl-link>
              </template>

              <template #version>
                <strong>{{ packageEntity.version }}</strong>
              </template>

              <template #name>
                <strong>{{ packageEntity.name }}</strong>
              </template>
            </gl-sprintf>
          </p>
        </gl-modal>
      </template>
    </delete-packages>
  </div>
</template>
