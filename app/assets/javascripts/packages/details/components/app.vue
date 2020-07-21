<script>
import {
  GlBadge,
  GlDeprecatedButton,
  GlIcon,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
  GlLink,
  GlEmptyState,
  GlTab,
  GlTabs,
  GlTable,
  GlSprintf,
} from '@gitlab/ui';
import Tracking from '~/tracking';
import PackageActivity from './activity.vue';
import PackageInformation from './information.vue';
import PackageTitle from './package_title.vue';
import ConanInstallation from './conan_installation.vue';
import MavenInstallation from './maven_installation.vue';
import NpmInstallation from './npm_installation.vue';
import NugetInstallation from './nuget_installation.vue';
import PypiInstallation from './pypi_installation.vue';
import PackagesListLoader from '../../shared/components/packages_list_loader.vue';
import PackageListRow from '../../shared/components/package_list_row.vue';
import DependencyRow from './dependency_row.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { generatePackageInfo } from '../utils';
import { __, s__ } from '~/locale';
import { PackageType, TrackingActions } from '../../shared/constants';
import { packageTypeToTrackCategory } from '../../shared/utils';
import { mapActions, mapState } from 'vuex';

export default {
  name: 'PackagesApp',
  components: {
    GlBadge,
    GlDeprecatedButton,
    GlEmptyState,
    GlLink,
    GlModal,
    GlTab,
    GlTabs,
    GlTable,
    GlIcon,
    GlSprintf,
    PackageActivity,
    PackageInformation,
    PackageTitle,
    ConanInstallation,
    MavenInstallation,
    NpmInstallation,
    NugetInstallation,
    PypiInstallation,
    PackagesListLoader,
    PackageListRow,
    DependencyRow,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  mixins: [timeagoMixin, Tracking.mixin()],
  trackingActions: { ...TrackingActions },
  computed: {
    ...mapState([
      'packageEntity',
      'packageFiles',
      'isLoading',
      'canDelete',
      'destroyPath',
      'svgPath',
      'npmPath',
      'npmHelpPath',
    ]),
    installationComponent() {
      switch (this.packageEntity.package_type) {
        case PackageType.CONAN:
          return ConanInstallation;
        case PackageType.MAVEN:
          return MavenInstallation;
        case PackageType.NPM:
          return NpmInstallation;
        case PackageType.NUGET:
          return NugetInstallation;
        case PackageType.PYPI:
          return PypiInstallation;
        default:
          return null;
      }
    },
    isValidPackage() {
      return Boolean(this.packageEntity.name);
    },
    canDeletePackage() {
      return this.canDelete && this.destroyPath;
    },
    packageInformation() {
      return generatePackageInfo(this.packageEntity);
    },
    packageMetadataTitle() {
      switch (this.packageEntity.package_type) {
        case PackageType.MAVEN:
          return s__('Maven Metadata');
        default:
          return s__('Package information');
      }
    },
    packageMetadata() {
      switch (this.packageEntity.package_type) {
        case PackageType.MAVEN:
          return [
            {
              label: s__('Group ID'),
              value: this.packageEntity.maven_metadatum.app_group,
            },
            {
              label: s__('Artifact ID'),
              value: this.packageEntity.maven_metadatum.app_name,
            },
            {
              label: s__('Version'),
              value: this.packageEntity.maven_metadatum.app_version,
            },
          ];
        default:
          return null;
      }
    },
    filesTableRows() {
      return this.packageFiles.map(x => ({
        name: x.file_name,
        downloadPath: x.download_path,
        size: this.formatSize(x.size),
        created: x.created_at,
      }));
    },
    tracking() {
      return {
        category: packageTypeToTrackCategory(this.packageEntity.package_type),
      };
    },
    hasVersions() {
      return this.packageEntity.versions?.length > 0;
    },
    packageDependencies() {
      return this.packageEntity.dependency_links || [];
    },
    showDependencies() {
      return this.packageEntity.package_type === PackageType.NUGET;
    },
  },
  methods: {
    ...mapActions(['fetchPackageVersions']),
    formatSize(size) {
      return numberToHumanSize(size);
    },
    cancelDelete() {
      this.$refs.deleteModal.hide();
    },
    getPackageVersions() {
      if (!this.packageEntity.versions) {
        this.fetchPackageVersions();
      }
    },
  },
  i18n: {
    deleteModalTitle: s__(`PackageRegistry|Delete Package Version`),
    deleteModalContent: s__(
      `PackageRegistry|You are about to delete version %{version} of %{name}. Are you sure?`,
    ),
  },
  filesTableHeaderFields: [
    {
      key: 'name',
      label: __('Name'),
      tdClass: 'd-flex align-items-center',
    },
    {
      key: 'size',
      label: __('Size'),
    },
    {
      key: 'created',
      label: __('Created'),
      class: 'text-right',
    },
  ],
};
</script>

<template>
  <gl-empty-state
    v-if="!isValidPackage"
    :title="s__('PackageRegistry|Unable to load package')"
    :description="s__('PackageRegistry|There was a problem fetching the details for this package.')"
    :svg-path="svgPath"
  />

  <div v-else class="packages-app">
    <div class="detail-page-header d-flex justify-content-between flex-column flex-sm-row">
      <package-title />

      <div class="mt-sm-2">
        <gl-deprecated-button
          v-if="canDeletePackage"
          v-gl-modal="'delete-modal'"
          class="js-delete-button"
          variant="danger"
          data-qa-selector="delete_button"
          >{{ __('Delete') }}</gl-deprecated-button
        >
      </div>
    </div>

    <gl-tabs>
      <gl-tab :title="__('Detail')">
        <div class="row" data-qa-selector="package_information_content">
          <div class="col-sm-6">
            <package-information :information="packageInformation" />
            <package-information
              v-if="packageMetadata"
              :heading="packageMetadataTitle"
              :information="packageMetadata"
              :show-copy="true"
            />
          </div>

          <div class="col-sm-6">
            <component
              :is="installationComponent"
              v-if="installationComponent"
              :name="packageEntity.name"
              :registry-url="npmPath"
              :help-url="npmHelpPath"
            />
          </div>
        </div>

        <package-activity />

        <gl-table
          :fields="$options.filesTableHeaderFields"
          :items="filesTableRows"
          tbody-tr-class="js-file-row"
        >
          <template #cell(name)="items">
            <gl-icon name="doc-code" class="space-right" />
            <gl-link
              :href="items.item.downloadPath"
              class="js-file-download"
              @click="track($options.trackingActions.PULL_PACKAGE)"
            >
              {{ items.item.name }}
            </gl-link>
          </template>

          <template #cell(created)="items">
            <span v-gl-tooltip :title="tooltipTitle(items.item.created)">{{
              timeFormatted(items.item.created)
            }}</span>
          </template>
        </gl-table>
      </gl-tab>

      <gl-tab v-if="showDependencies" title-item-class="js-dependencies-tab">
        <template #title>
          <span>{{ __('Dependencies') }}</span>
          <gl-badge size="sm" data-testid="dependencies-badge">{{
            packageDependencies.length
          }}</gl-badge>
        </template>

        <template v-if="packageDependencies.length > 0">
          <dependency-row
            v-for="(dep, index) in packageDependencies"
            :key="index"
            :dependency="dep"
          />
        </template>

        <p v-else class="gl-mt-3" data-testid="no-dependencies-message">
          {{ s__('PackageRegistry|This NuGet package has no dependencies.') }}
        </p>
      </gl-tab>

      <gl-tab
        :title="__('Versions')"
        title-item-class="js-versions-tab"
        @click="getPackageVersions"
      >
        <template v-if="isLoading && !hasVersions">
          <packages-list-loader />
        </template>

        <template v-else-if="hasVersions">
          <package-list-row
            v-for="v in packageEntity.versions"
            :key="v.id"
            :package-entity="{ name: packageEntity.name, ...v }"
            :package-link="v.id.toString()"
            :disable-delete="true"
            :show-package-type="false"
          />
        </template>

        <p v-else class="gl-mt-3" data-testid="no-versions-message">
          {{ s__('PackageRegistry|There are no other versions of this package.') }}
        </p>
      </gl-tab>
    </gl-tabs>

    <gl-modal ref="deleteModal" class="js-delete-modal" modal-id="delete-modal">
      <template #modal-title>{{ $options.i18n.deleteModalTitle }}</template>
      <gl-sprintf :message="$options.i18n.deleteModalContent">
        <template #version>
          <strong>{{ packageEntity.version }}</strong>
        </template>

        <template #name>
          <strong>{{ packageEntity.name }}</strong>
        </template>
      </gl-sprintf>

      <div slot="modal-footer" class="w-100">
        <div class="float-right">
          <gl-deprecated-button @click="cancelDelete()">{{ __('Cancel') }}</gl-deprecated-button>
          <gl-deprecated-button
            ref="modal-delete-button"
            data-method="delete"
            :to="destroyPath"
            variant="danger"
            data-qa-selector="delete_modal_button"
            @click="track($options.trackingActions.DELETE_PACKAGE)"
            >{{ __('Delete') }}</gl-deprecated-button
          >
        </div>
      </div>
    </gl-modal>
  </div>
</template>
