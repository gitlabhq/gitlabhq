<script>
import {
  GlButton,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
  GlEmptyState,
  GlTab,
  GlTabs,
  GlSprintf,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { objectToQuery } from '~/lib/utils/url_utility';
import { s__, __ } from '~/locale';
import TerraformTitle from '~/packages_and_registries/infrastructure_registry/details/components/details_title.vue';
import TerraformInstallation from '~/packages_and_registries/infrastructure_registry/details/components/terraform_installation.vue';
import Tracking from '~/tracking';
import PackageListRow from '~/packages_and_registries/infrastructure_registry/shared/package_list_row.vue';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import {
  TRACKING_ACTIONS,
  SHOW_DELETE_SUCCESS_ALERT,
} from '~/packages_and_registries/shared/constants';
import { TRACK_CATEGORY } from '~/packages_and_registries/infrastructure_registry/shared/constants';
import PackageFiles from './package_files.vue';
import PackageHistory from './package_history.vue';

export default {
  name: 'PackagesApp',
  components: {
    GlButton,
    GlEmptyState,
    GlModal,
    GlTab,
    GlTabs,
    GlSprintf,
    TerraformTitle,
    PackagesListLoader,
    PackageListRow,
    PackageHistory,
    TerraformInstallation,
    PackageFiles,
    Markdown: () => import('~/vue_shared/components/markdown/markdown_content.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  mixins: [Tracking.mixin()],
  trackingActions: { ...TRACKING_ACTIONS },
  inject: ['projectName', 'canDelete', 'svgPath', 'projectListUrl'],
  data() {
    return {
      fileToDelete: null,
    };
  },
  computed: {
    ...mapState(['packageEntity', 'packageFiles', 'isLoading']),
    isValidPackage() {
      return Boolean(this.packageEntity.name);
    },
    readme() {
      return this.packageEntity.terraform_module_metadatum?.fields?.root?.readme;
    },
    tracking() {
      return {
        category: TRACK_CATEGORY,
      };
    },
    hasVersions() {
      return this.packageEntity.versions?.length > 0;
    },
  },
  methods: {
    ...mapActions(['deletePackage', 'fetchPackageVersions', 'deletePackageFile']),
    formatSize(size) {
      return numberToHumanSize(size);
    },
    getPackageVersions() {
      if (!this.packageEntity.versions) {
        this.fetchPackageVersions();
      }
    },
    packageEntityWithName(version) {
      return {
        name: this.packageEntity.name,
        ...version,
      };
    },
    async confirmPackageDeletion() {
      this.track(TRACKING_ACTIONS.DELETE_PACKAGE);
      await this.deletePackage();
      const returnTo = this.projectListUrl;
      const modalQuery = objectToQuery({ [SHOW_DELETE_SUCCESS_ALERT]: true });
      window.location.replace(`${returnTo}?${modalQuery}`);
    },
    handleFileDelete(file) {
      this.track(TRACKING_ACTIONS.REQUEST_DELETE_PACKAGE_FILE);
      this.fileToDelete = { ...file };
      this.$refs.deleteFileModal.show();
    },
    confirmFileDelete() {
      this.track(TRACKING_ACTIONS.DELETE_PACKAGE_FILE);
      this.deletePackageFile(this.fileToDelete.id);
      this.fileToDelete = null;
    },
  },
  i18n: {
    deleteModalTitle: s__(`PackageRegistry|Delete Package Version`),
    deleteModalContent: s__(
      `PackageRegistry|You are about to delete version %{version} of %{name}. Are you sure?`,
    ),
    deleteFileModalTitle: s__(`PackageRegistry|Delete package asset`),
    deleteFileModalContent: s__(
      `PackageRegistry|You are about to delete %{filename}. This is a destructive action that may render your package unusable. Are you sure?`,
    ),
  },
  modal: {
    packageDeletePrimaryAction: {
      text: __('Delete'),
      attributes: {
        variant: 'danger',
        category: 'primary',
      },
    },
    fileDeletePrimaryAction: {
      text: __('Delete'),
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
    :svg-path="svgPath"
    :svg-height="null"
  />

  <div v-else class="packages-app">
    <terraform-title>
      <template #delete-button>
        <gl-button
          v-if="canDelete"
          v-gl-modal="'delete-modal'"
          class="js-delete-button"
          variant="danger"
          category="primary"
        >
          {{ __('Delete') }}
        </gl-button>
      </template>
    </terraform-title>

    <gl-tabs>
      <gl-tab :title="__('Detail')">
        <div>
          <package-history :package-entity="packageEntity" :project-name="projectName" />
          <terraform-installation
            :package-name="packageEntity.name"
            :package-version="packageEntity.version"
          />
        </div>

        <package-files
          :package-files="packageFiles"
          :can-delete="canDelete"
          @download-file="track($options.trackingActions.PULL_PACKAGE)"
          @delete-file="handleFileDelete"
        />
      </gl-tab>

      <gl-tab
        :title="__('Other versions')"
        title-item-class="js-versions-tab"
        @click="getPackageVersions"
      >
        <template v-if="isLoading && !hasVersions">
          <packages-list-loader />
        </template>

        <template v-else-if="hasVersions">
          <ul class="gl-pl-0">
            <li v-for="v in packageEntity.versions" :key="v.id" class="gl-list-none">
              <package-list-row
                :package-entity="packageEntityWithName(v)"
                :package-link="v.id.toString()"
                :disable-delete="true"
                :show-package-type="false"
              />
            </li>
          </ul>
        </template>

        <p v-else class="gl-mt-3" data-testid="no-versions-message">
          {{ s__('PackageRegistry|There are no other versions of this package.') }}
        </p>
      </gl-tab>

      <gl-tab v-if="readme" :title="s__('PackageRegistry|Readme')" lazy>
        <markdown :value="readme" />
      </gl-tab>
    </gl-tabs>

    <gl-modal
      ref="deleteModal"
      size="sm"
      modal-id="delete-modal"
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
      size="sm"
      modal-id="delete-file-modal"
      :action-primary="$options.modal.fileDeletePrimaryAction"
      :action-cancel="$options.modal.cancelAction"
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
