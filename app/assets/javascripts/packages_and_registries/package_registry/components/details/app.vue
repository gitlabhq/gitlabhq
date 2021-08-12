<script>
import {
  GlBadge,
  GlButton,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
  GlEmptyState,
  GlTab,
  GlTabs,
  GlSprintf,
} from '@gitlab/ui';
import createFlash from '~/flash';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { objectToQuery } from '~/lib/utils/url_utility';
import { s__, __ } from '~/locale';
import { packageTypeToTrackCategory } from '~/packages/shared/utils';
import AdditionalMetadata from '~/packages_and_registries/package_registry/components/details/additional_metadata.vue';
import DependencyRow from '~/packages_and_registries/package_registry/components/details/dependency_row.vue';
import InstallationCommands from '~/packages_and_registries/package_registry/components/details/installation_commands.vue';
import PackageFiles from '~/packages_and_registries/package_registry/components/details/package_files.vue';
import PackageHistory from '~/packages_and_registries/package_registry/components/details/package_history.vue';
import PackageTitle from '~/packages_and_registries/package_registry/components/details/package_title.vue';
import VersionRow from '~/packages_and_registries/package_registry/components/details/version_row.vue';
import {
  PACKAGE_TYPE_NUGET,
  PACKAGE_TYPE_COMPOSER,
  DELETE_PACKAGE_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGE_TRACKING_ACTION,
  CANCEL_DELETE_PACKAGE_TRACKING_ACTION,
  PULL_PACKAGE_TRACKING_ACTION,
  DELETE_PACKAGE_FILE_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGE_FILE_TRACKING_ACTION,
  CANCEL_DELETE_PACKAGE_FILE_TRACKING_ACTION,
  SHOW_DELETE_SUCCESS_ALERT,
  FETCH_PACKAGE_DETAILS_ERROR_MESSAGE,
  DELETE_PACKAGE_ERROR_MESSAGE,
  DELETE_PACKAGE_FILE_ERROR_MESSAGE,
  DELETE_PACKAGE_FILE_SUCCESS_MESSAGE,
} from '~/packages_and_registries/package_registry/constants';

import destroyPackageMutation from '~/packages_and_registries/package_registry/graphql/mutations/destroy_package.mutation.graphql';
import destroyPackageFileMutation from '~/packages_and_registries/package_registry/graphql/mutations/destroy_package_file.mutation.graphql';
import getPackageDetails from '~/packages_and_registries/package_registry/graphql/queries/get_package_details.query.graphql';
import Tracking from '~/tracking';

export default {
  name: 'PackagesApp',
  components: {
    GlBadge,
    GlButton,
    GlEmptyState,
    GlModal,
    GlTab,
    GlTabs,
    GlSprintf,
    PackageTitle,
    VersionRow,
    DependencyRow,
    PackageHistory,
    AdditionalMetadata,
    InstallationCommands,
    PackageFiles,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  mixins: [Tracking.mixin()],
  inject: [
    'packageId',
    'projectName',
    'canDelete',
    'svgPath',
    'npmPath',
    'npmHelpPath',
    'projectListUrl',
    'groupListUrl',
  ],
  trackingActions: {
    DELETE_PACKAGE_TRACKING_ACTION,
    REQUEST_DELETE_PACKAGE_TRACKING_ACTION,
    CANCEL_DELETE_PACKAGE_TRACKING_ACTION,
    PULL_PACKAGE_TRACKING_ACTION,
    DELETE_PACKAGE_FILE_TRACKING_ACTION,
    REQUEST_DELETE_PACKAGE_FILE_TRACKING_ACTION,
    CANCEL_DELETE_PACKAGE_FILE_TRACKING_ACTION,
  },
  data() {
    return {
      fileToDelete: null,
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
        return data.package;
      },
      error(error) {
        createFlash({
          message: FETCH_PACKAGE_DETAILS_ERROR_MESSAGE,
          captureError: true,
          error,
        });
      },
    },
  },
  computed: {
    queryVariables() {
      return {
        id: convertToGraphQLId('Packages::Package', this.packageId),
      };
    },
    packageFiles() {
      return this.packageEntity?.packageFiles?.nodes;
    },
    isLoading() {
      return this.$apollo.queries.packageEntity.loading;
    },
    isValidPackage() {
      return this.isLoading || Boolean(this.packageEntity?.name);
    },
    tracking() {
      return {
        category: packageTypeToTrackCategory(this.packageEntity.packageType),
      };
    },
    hasVersions() {
      return this.packageEntity.versions?.nodes?.length > 0;
    },
    packageDependencies() {
      return this.packageEntity.dependencyLinks?.nodes || [];
    },
    showDependencies() {
      return this.packageEntity.packageType === PACKAGE_TYPE_NUGET;
    },
    showFiles() {
      return this.packageEntity?.packageType !== PACKAGE_TYPE_COMPOSER;
    },
  },
  methods: {
    formatSize(size) {
      return numberToHumanSize(size);
    },
    async deletePackage() {
      const { data } = await this.$apollo.mutate({
        mutation: destroyPackageMutation,
        variables: {
          id: this.packageEntity.id,
        },
      });

      if (data?.destroyPackage?.errors[0]) {
        throw data.destroyPackage.errors[0];
      }
    },
    async confirmPackageDeletion() {
      this.track(DELETE_PACKAGE_TRACKING_ACTION);

      try {
        await this.deletePackage();

        const returnTo =
          !this.groupListUrl || document.referrer.includes(this.projectName)
            ? this.projectListUrl
            : this.groupListUrl; // to avoid security issue url are supplied from backend

        const modalQuery = objectToQuery({ [SHOW_DELETE_SUCCESS_ALERT]: true });

        window.location.replace(`${returnTo}?${modalQuery}`);
      } catch (error) {
        createFlash({
          message: DELETE_PACKAGE_ERROR_MESSAGE,
          type: 'warning',
          captureError: true,
          error,
        });
      }
    },
    async deletePackageFile(id) {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: destroyPackageFileMutation,
          variables: {
            id,
          },
          awaitRefetchQueries: true,
          refetchQueries: [
            {
              query: getPackageDetails,
              variables: this.queryVariables,
            },
          ],
        });
        if (data?.destroyPackageFile?.errors[0]) {
          throw data.destroyPackageFile.errors[0];
        }
        createFlash({
          message: DELETE_PACKAGE_FILE_SUCCESS_MESSAGE,
          type: 'success',
        });
      } catch (error) {
        createFlash({
          message: DELETE_PACKAGE_FILE_ERROR_MESSAGE,
          type: 'warning',
          captureError: true,
          error,
        });
      }
    },
    handleFileDelete(file) {
      this.track(REQUEST_DELETE_PACKAGE_FILE_TRACKING_ACTION);
      this.fileToDelete = { ...file };
      this.$refs.deleteFileModal.show();
    },
    confirmFileDelete() {
      this.track(DELETE_PACKAGE_FILE_TRACKING_ACTION);
      this.deletePackageFile(this.fileToDelete.id);
      this.fileToDelete = null;
    },
  },
  i18n: {
    deleteModalTitle: s__(`PackageRegistry|Delete Package Version`),
    deleteModalContent: s__(
      `PackageRegistry|You are about to delete version %{version} of %{name}. Are you sure?`,
    ),
    deleteFileModalTitle: s__(`PackageRegistry|Delete Package File`),
    deleteFileModalContent: s__(
      `PackageRegistry|You are about to delete %{filename}. This is a destructive action that may render your package unusable. Are you sure?`,
    ),
  },
  modal: {
    packageDeletePrimaryAction: {
      text: __('Delete'),
      attributes: [
        { variant: 'danger' },
        { category: 'primary' },
        { 'data-qa-selector': 'delete_modal_button' },
      ],
    },
    fileDeletePrimaryAction: {
      text: __('Delete'),
      attributes: [{ variant: 'danger' }, { category: 'primary' }],
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
    :svg-path="svgPath"
  />
  <div v-else-if="!isLoading" class="packages-app">
    <package-title :package-entity="packageEntity">
      <template #delete-button>
        <gl-button
          v-if="canDelete"
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

          <additional-metadata :package-entity="packageEntity" />
        </div>

        <package-files
          v-if="showFiles"
          :package-files="packageFiles"
          @download-file="track($options.trackingActions.PULL_PACKAGE)"
          @delete-file="handleFileDelete"
        />
      </gl-tab>

      <gl-tab v-if="showDependencies">
        <template #title>
          <span>{{ __('Dependencies') }}</span>
          <gl-badge size="sm">{{ packageDependencies.length }}</gl-badge>
        </template>

        <template v-if="packageDependencies.length > 0">
          <dependency-row v-for="dep in packageDependencies" :key="dep.id" :dependency-link="dep" />
        </template>

        <p v-else class="gl-mt-3" data-testid="no-dependencies-message">
          {{ s__('PackageRegistry|This NuGet package has no dependencies.') }}
        </p>
      </gl-tab>

      <gl-tab :title="__('Other versions')" title-item-class="js-versions-tab">
        <template v-if="hasVersions">
          <version-row v-for="v in packageEntity.versions.nodes" :key="v.id" :package-entity="v" />
        </template>

        <p v-else class="gl-mt-3" data-testid="no-versions-message">
          {{ s__('PackageRegistry|There are no other versions of this package.') }}
        </p>
      </gl-tab>
    </gl-tabs>

    <gl-modal
      ref="deleteModal"
      modal-id="delete-modal"
      data-testid="delete-modal"
      :action-primary="$options.modal.packageDeletePrimaryAction"
      :action-cancel="$options.modal.cancelAction"
      @primary="confirmPackageDeletion"
      @canceled="track($options.trackingActions.CANCEL_DELETE_PACKAGE)"
    >
      <template #modal-title>{{ $options.i18n.deleteModalTitle }}</template>
      <gl-sprintf :message="$options.i18n.deleteModalContent">
        <template #version>
          <strong>{{ packageEntity.version }}</strong>
        </template>

        <template #name>
          <strong>{{ packageEntity.name }}</strong>
        </template>
      </gl-sprintf>
    </gl-modal>

    <gl-modal
      ref="deleteFileModal"
      modal-id="delete-file-modal"
      :action-primary="$options.modal.fileDeletePrimaryAction"
      :action-cancel="$options.modal.cancelAction"
      data-testid="delete-file-modal"
      @primary="confirmFileDelete"
      @canceled="track($options.trackingActions.CANCEL_DELETE_PACKAGE_FILE)"
    >
      <template #modal-title>{{ $options.i18n.deleteFileModalTitle }}</template>
      <gl-sprintf v-if="fileToDelete" :message="$options.i18n.deleteFileModalContent">
        <template #filename>
          <strong>{{ fileToDelete.file_name }}</strong>
        </template>
      </gl-sprintf>
    </gl-modal>
  </div>
</template>
