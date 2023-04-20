<script>
import {
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
import { createAlert, VARIANT_SUCCESS, VARIANT_WARNING } from '~/alert';
import { TYPENAME_PACKAGES_PACKAGE } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { objectToQuery } from '~/lib/utils/url_utility';
import { s__, __ } from '~/locale';
import { packageTypeToTrackCategory } from '~/packages_and_registries/package_registry/utils';
import AdditionalMetadata from '~/packages_and_registries/package_registry/components/details/additional_metadata.vue';
import DependencyRow from '~/packages_and_registries/package_registry/components/details/dependency_row.vue';
import InstallationCommands from '~/packages_and_registries/package_registry/components/details/installation_commands.vue';
import PackageFiles from '~/packages_and_registries/package_registry/components/details/package_files.vue';
import PackageHistory from '~/packages_and_registries/package_registry/components/details/package_history.vue';
import PackageTitle from '~/packages_and_registries/package_registry/components/details/package_title.vue';
import PackageVersionsList from '~/packages_and_registries/package_registry/components/details/package_versions_list.vue';
import DeletePackages from '~/packages_and_registries/package_registry/components/functional/delete_packages.vue';
import {
  PACKAGE_TYPE_NUGET,
  PACKAGE_TYPE_COMPOSER,
  PACKAGE_TYPE_CONAN,
  PACKAGE_TYPE_MAVEN,
  PACKAGE_TYPE_PYPI,
  DELETE_PACKAGE_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGE_TRACKING_ACTION,
  CANCEL_DELETE_PACKAGE_TRACKING_ACTION,
  DELETE_PACKAGE_FILE_TRACKING_ACTION,
  DELETE_PACKAGE_FILES_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGE_FILE_TRACKING_ACTION,
  REQUEST_FORWARDING_HELP_PAGE_PATH,
  CANCEL_DELETE_PACKAGE_FILE_TRACKING_ACTION,
  SHOW_DELETE_SUCCESS_ALERT,
  FETCH_PACKAGE_DETAILS_ERROR_MESSAGE,
  DELETE_PACKAGE_FILE_ERROR_MESSAGE,
  DELETE_PACKAGE_FILE_SUCCESS_MESSAGE,
  DELETE_PACKAGE_FILES_ERROR_MESSAGE,
  DELETE_PACKAGE_FILES_SUCCESS_MESSAGE,
  DELETE_PACKAGE_REQUEST_FORWARDING_MODAL_CONTENT,
  DOWNLOAD_PACKAGE_ASSET_TRACKING_ACTION,
  DELETE_MODAL_TITLE,
  DELETE_MODAL_CONTENT,
  DELETE_ALL_PACKAGE_FILES_MODAL_CONTENT,
  DELETE_LAST_PACKAGE_FILE_MODAL_CONTENT,
  GRAPHQL_PAGE_SIZE,
} from '~/packages_and_registries/package_registry/constants';

import destroyPackageFilesMutation from '~/packages_and_registries/package_registry/graphql/mutations/destroy_package_files.mutation.graphql';
import getPackageDetails from '~/packages_and_registries/package_registry/graphql/queries/get_package_details.query.graphql';
import getPackageVersionsQuery from '~/packages_and_registries/package_registry/graphql/queries/get_package_versions.query.graphql';
import Tracking from '~/tracking';

export default {
  name: 'PackagesApp',
  components: {
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
    PackageFiles,
    DeletePackages,
    PackageVersionsList,
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
    DELETE_PACKAGE_FILE_TRACKING_ACTION,
    REQUEST_DELETE_PACKAGE_FILE_TRACKING_ACTION,
    CANCEL_DELETE_PACKAGE_FILE_TRACKING_ACTION,
    DOWNLOAD_PACKAGE_ASSET_TRACKING_ACTION,
  },
  data() {
    return {
      deletePackageModalContent: DELETE_MODAL_CONTENT,
      filesToDelete: [],
      mutationLoading: false,
      versionsMutationLoading: false,
      packageEntity: {},
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
          `${this.packageEntity?.name} v ${this.packageEntity?.version}`,
        );
      },
    },
  },
  computed: {
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
    packageFiles() {
      return this.packageEntity.packageFiles?.nodes;
    },
    packageType() {
      return this.packageEntity.packageType;
    },
    isLoading() {
      return this.$apollo.queries.packageEntity.loading;
    },
    packageFilesLoading() {
      return this.isLoading || this.mutationLoading;
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
    showFiles() {
      return this.packageType !== PACKAGE_TYPE_COMPOSER;
    },
    groupSettings() {
      return this.packageEntity.project?.group?.packageSettings ?? {};
    },
    isRequestForwardingEnabled() {
      return this.groupSettings[`${this.packageType.toLowerCase()}PackageRequestsForwarding`];
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
    refetchQueriesData() {
      return [
        {
          query: getPackageDetails,
          variables: this.queryVariables,
        },
      ];
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
    async deletePackageFiles(ids) {
      this.mutationLoading = true;
      try {
        const { data } = await this.$apollo.mutate({
          mutation: destroyPackageFilesMutation,
          variables: {
            projectPath: this.projectPath,
            ids,
          },
          awaitRefetchQueries: true,
          refetchQueries: this.refetchQueriesData,
        });
        if (data?.destroyPackageFiles?.errors[0]) {
          throw data.destroyPackageFiles.errors[0];
        }
        createAlert({
          message: this.isLastItem(ids)
            ? DELETE_PACKAGE_FILE_SUCCESS_MESSAGE
            : DELETE_PACKAGE_FILES_SUCCESS_MESSAGE,
          variant: VARIANT_SUCCESS,
        });
      } catch (error) {
        createAlert({
          message: this.isLastItem(ids)
            ? DELETE_PACKAGE_FILE_ERROR_MESSAGE
            : DELETE_PACKAGE_FILES_ERROR_MESSAGE,
          variant: VARIANT_WARNING,
          captureError: true,
          error,
        });
      }
      this.mutationLoading = false;
    },
    handleFileDelete(files) {
      this.track(REQUEST_DELETE_PACKAGE_FILE_TRACKING_ACTION);
      if (
        files.length === this.packageFiles.length &&
        !this.packageEntity.packageFiles?.pageInfo?.hasNextPage
      ) {
        if (this.isLastItem(files)) {
          this.deletePackageModalContent = DELETE_LAST_PACKAGE_FILE_MODAL_CONTENT;
        } else {
          this.deletePackageModalContent = DELETE_ALL_PACKAGE_FILES_MODAL_CONTENT;
        }
        this.$refs.deleteModal.show();
      } else {
        this.filesToDelete = files;
        if (this.isLastItem(files)) {
          this.$refs.deleteFileModal.show();
        } else if (files.length > 1) {
          this.$refs.deleteFilesModal.show();
        }
      }
    },
    isLastItem(items) {
      return items.length === 1;
    },
    confirmFilesDelete() {
      if (this.isLastItem(this.filesToDelete)) {
        this.track(DELETE_PACKAGE_FILE_TRACKING_ACTION);
      } else {
        this.track(DELETE_PACKAGE_FILES_TRACKING_ACTION);
      }
      this.deletePackageFiles(this.filesToDelete.map((file) => file.id));
      this.filesToDelete = [];
    },
    resetDeleteModalContent() {
      this.deletePackageModalContent = DELETE_MODAL_CONTENT;
    },
  },
  i18n: {
    DELETE_MODAL_TITLE,
    deleteFileModalTitle: s__(`PackageRegistry|Delete package asset`),
    deleteFileModalContent: s__(
      `PackageRegistry|You are about to delete %{filename}. This is a destructive action that may render your package unusable. Are you sure?`,
    ),
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
        'data-qa-selector': 'delete_modal_button',
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
  />
  <div v-else-if="projectName" class="packages-app">
    <package-title :package-entity="packageEntity">
      <template #delete-button>
        <gl-button
          v-if="packageEntity.canDestroy"
          v-gl-modal="'delete-modal'"
          variant="danger"
          category="primary"
          data-qa-selector="delete_button"
          data-testid="delete-package"
        >
          {{ __('Delete') }}
        </gl-button>
      </template>
    </package-title>

    <gl-tabs>
      <gl-tab :title="__('Detail')">
        <div v-if="!isLoading" data-qa-selector="package_information_content">
          <package-history :package-entity="packageEntity" :project-name="projectName" />

          <installation-commands :package-entity="packageEntity" />

          <additional-metadata
            v-if="showMetadata"
            :package-id="packageEntity.id"
            :package-type="packageType"
          />
        </div>

        <package-files
          v-if="showFiles"
          :can-delete="packageEntity.canDestroy"
          :is-loading="packageFilesLoading"
          :package-files="packageFiles"
          @download-file="track($options.trackingActions.DOWNLOAD_PACKAGE_ASSET_TRACKING_ACTION)"
          @delete-files="handleFileDelete"
        />
      </gl-tab>

      <gl-tab v-if="showDependencies">
        <template #title>
          <span>{{ __('Dependencies') }}</span>
          <gl-badge size="sm" data-testid="dependencies-badge">{{
            packageDependencies.length
          }}</gl-badge>
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
          <gl-badge size="sm" class="gl-tab-counter-badge" data-testid="other-versions-badge">{{
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
              :can-destroy="packageEntity.canDestroy"
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

    <gl-modal
      ref="deleteFileModal"
      size="sm"
      modal-id="delete-file-modal"
      :action-primary="$options.modal.fileDeletePrimaryAction"
      :action-cancel="$options.modal.cancelAction"
      data-testid="delete-file-modal"
      @primary="confirmFilesDelete"
      @canceled="track($options.trackingActions.CANCEL_DELETE_PACKAGE_FILE)"
    >
      <template #modal-title>{{ $options.i18n.deleteFileModalTitle }}</template>
      <gl-sprintf v-if="isLastItem(filesToDelete)" :message="$options.i18n.deleteFileModalContent">
        <template #filename>
          <strong>{{ filesToDelete[0].fileName }}</strong>
        </template>
      </gl-sprintf>
    </gl-modal>

    <gl-modal
      ref="deleteFilesModal"
      size="sm"
      modal-id="delete-files-modal"
      :action-primary="$options.modal.filesDeletePrimaryAction"
      :action-cancel="$options.modal.cancelAction"
      data-testid="delete-files-modal"
      @primary="confirmFilesDelete"
      @canceled="track($options.trackingActions.CANCEL_DELETE_PACKAGE_FILE)"
    >
      <template #modal-title>{{
        n__(
          `PackageRegistry|Delete 1 asset`,
          `PackageRegistry|Delete %d assets`,
          filesToDelete.length,
        )
      }}</template>
      <span v-if="filesToDelete.length > 0">
        {{
          n__(
            `PackageRegistry|You are about to delete 1 asset. This operation is irreversible.`,
            `PackageRegistry|You are about to delete %d assets. This operation is irreversible.`,
            filesToDelete.length,
          )
        }}
      </span>
    </gl-modal>
  </div>
</template>
