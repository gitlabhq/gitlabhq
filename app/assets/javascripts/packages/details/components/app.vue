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
import { mapActions, mapState } from 'vuex';
import { objectToQueryString } from '~/lib/utils/common_utils';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import PackageListRow from '../../shared/components/package_list_row.vue';
import PackagesListLoader from '../../shared/components/packages_list_loader.vue';
import { PackageType, TrackingActions, SHOW_DELETE_SUCCESS_ALERT } from '../../shared/constants';
import { packageTypeToTrackCategory } from '../../shared/utils';
import AdditionalMetadata from './additional_metadata.vue';
import DependencyRow from './dependency_row.vue';
import InstallationCommands from './installation_commands.vue';
import PackageFiles from './package_files.vue';
import PackageHistory from './package_history.vue';
import PackageTitle from './package_title.vue';

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
    PackagesListLoader,
    PackageListRow,
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
  trackingActions: { ...TrackingActions },
  computed: {
    ...mapState([
      'projectName',
      'packageEntity',
      'packageFiles',
      'isLoading',
      'canDelete',
      'svgPath',
      'npmPath',
      'npmHelpPath',
      'projectListUrl',
      'groupListUrl',
    ]),
    isValidPackage() {
      return Boolean(this.packageEntity.name);
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
    showFiles() {
      return this.packageEntity?.package_type !== PackageType.COMPOSER;
    },
  },
  methods: {
    ...mapActions(['deletePackage', 'fetchPackageVersions']),
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
    async confirmPackageDeletion() {
      this.track(TrackingActions.DELETE_PACKAGE);
      await this.deletePackage();
      const returnTo =
        !this.groupListUrl || document.referrer.includes(this.projectName)
          ? this.projectListUrl
          : this.groupListUrl; // to avoid security issue url are supplied from backend
      const modalQuery = objectToQueryString({ [SHOW_DELETE_SUCCESS_ALERT]: true });
      window.location.replace(`${returnTo}?${modalQuery}`);
    },
  },
  i18n: {
    deleteModalTitle: s__(`PackageRegistry|Delete Package Version`),
    deleteModalContent: s__(
      `PackageRegistry|You are about to delete version %{version} of %{name}. Are you sure?`,
    ),
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

  <div v-else class="packages-app">
    <package-title>
      <template #delete-button>
        <gl-button
          v-if="canDelete"
          v-gl-modal="'delete-modal'"
          class="js-delete-button"
          variant="danger"
          category="primary"
          data-qa-selector="delete_button"
        >
          {{ __('Delete') }}
        </gl-button>
      </template>
    </package-title>

    <gl-tabs>
      <gl-tab :title="__('Detail')">
        <div data-qa-selector="package_information_content">
          <package-history :package-entity="packageEntity" :project-name="projectName" />

          <installation-commands
            :package-entity="packageEntity"
            :npm-path="npmPath"
            :npm-help-path="npmHelpPath"
          />

          <additional-metadata :package-entity="packageEntity" />
        </div>

        <package-files
          v-if="showFiles"
          :package-files="packageFiles"
          @download-file="track($options.trackingActions.PULL_PACKAGE)"
        />
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
        :title="__('Other versions')"
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

      <template #modal-footer>
        <div class="gl-w-full">
          <div class="float-right">
            <gl-button @click="cancelDelete">{{ __('Cancel') }}</gl-button>
            <gl-button
              ref="modal-delete-button"
              variant="danger"
              category="primary"
              data-qa-selector="delete_modal_button"
              @click="confirmPackageDeletion"
            >
              {{ __('Delete') }}
            </gl-button>
          </div>
        </div>
      </template>
    </gl-modal>
  </div>
</template>
