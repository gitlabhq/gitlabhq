<script>
import {
  GlAlert,
  GlLink,
  GlTable,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlButton,
  GlFormCheckbox,
  GlLoadingIcon,
  GlModal,
  GlSprintf,
  GlKeysetPagination,
} from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { createAlert, VARIANT_SUCCESS, VARIANT_WARNING } from '~/alert';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { scrollToElement } from '~/lib/utils/common_utils';
import { __, s__ } from '~/locale';
import FileSha from '~/packages_and_registries/package_registry/components/details/file_sha.vue';
import Tracking from '~/tracking';
import { packageTypeToTrackCategory } from '~/packages_and_registries/package_registry/utils';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import {
  FETCH_PACKAGE_FILES_ERROR_MESSAGE,
  GRAPHQL_PACKAGE_FILES_PAGE_SIZE,
  REQUEST_DELETE_SELECTED_PACKAGE_FILE_TRACKING_ACTION,
  SELECT_PACKAGE_FILE_TRACKING_ACTION,
  DOWNLOAD_PACKAGE_ASSET_TRACKING_ACTION,
  CANCEL_DELETE_PACKAGE_FILE_TRACKING_ACTION,
  DELETE_PACKAGE_FILE_TRACKING_ACTION,
  REQUEST_DELETE_PACKAGE_FILE_TRACKING_ACTION,
  TRACKING_LABEL_PACKAGE_ASSET,
  TRACKING_ACTION_EXPAND_PACKAGE_ASSET,
  DELETE_PACKAGE_FILE_ERROR_MESSAGE,
  DELETE_PACKAGE_FILE_SUCCESS_MESSAGE,
  DELETE_PACKAGE_FILES_ERROR_MESSAGE,
  DELETE_PACKAGE_FILES_SUCCESS_MESSAGE,
  DELETE_PACKAGE_FILES_TRACKING_ACTION,
  DELETE_ALL_PACKAGE_FILES_MODAL_CONTENT,
  DELETE_LAST_PACKAGE_FILE_MODAL_CONTENT,
} from '~/packages_and_registries/package_registry/constants';
import getPackageFilesQuery from '~/packages_and_registries/package_registry/graphql/queries/get_package_files.query.graphql';
import destroyPackageFilesMutation from '~/packages_and_registries/package_registry/graphql/mutations/destroy_package_files.mutation.graphql';

export default {
  name: 'PackageFiles',
  components: {
    GlAlert,
    GlLink,
    GlTable,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlFormCheckbox,
    GlButton,
    GlLoadingIcon,
    GlModal,
    GlKeysetPagination,
    GlSprintf,
    FileIcon,
    TimeAgoTooltip,
    FileSha,
  },
  mixins: [Tracking.mixin()],
  trackingActions: {
    DELETE_PACKAGE_FILE_TRACKING_ACTION,
    REQUEST_DELETE_PACKAGE_FILE_TRACKING_ACTION,
    CANCEL_DELETE_PACKAGE_FILE_TRACKING_ACTION,
    DOWNLOAD_PACKAGE_ASSET_TRACKING_ACTION,
  },
  props: {
    canDelete: {
      type: Boolean,
      required: false,
      default: false,
    },
    deleteAllFiles: {
      type: Boolean,
      required: false,
      default: false,
    },
    packageId: {
      type: String,
      required: true,
    },
    packageType: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
  },
  apollo: {
    packageFiles: {
      query: getPackageFilesQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data.package?.packageFiles?.nodes ?? [];
      },
      result({ data }) {
        const { packageFiles } = data?.package ?? {};
        if (packageFiles?.pageInfo) {
          this.pageInfo = packageFiles.pageInfo;
        }
      },
      error(error) {
        this.fetchPackageFilesError = true;
        Sentry.captureException(error);
      },
    },
  },
  data() {
    return {
      fetchPackageFilesError: false,
      filesToDelete: [],
      packageFiles: [],
      mutationLoading: false,
      selectedReferences: [],
      pageInfo: {},
    };
  },
  computed: {
    areFilesSelected() {
      return this.selectedReferences.length > 0;
    },
    areAllFilesSelected() {
      return this.packageFiles.length > 0 && this.packageFiles.every(this.isSelected);
    },
    filesTableRows() {
      return this.packageFiles.map((pf) => ({
        ...pf,
        size: this.formatSize(pf.size),
      }));
    },
    hasSelectedSomeFiles() {
      return this.areFilesSelected && !this.areAllFilesSelected;
    },
    isLoading() {
      return this.$apollo.queries.packageFiles.loading || this.mutationLoading;
    },
    isLastPage() {
      return !this.pageInfo.hasPreviousPage && !this.pageInfo.hasNextPage;
    },
    filesTableHeaderFields() {
      return [
        {
          key: 'checkbox',
          label: __('Select all'),
          thClass: 'gl-w-4',
          hide: !this.canDelete,
        },
        {
          key: 'name',
          label: __('Name'),
        },
        {
          key: 'size',
          label: __('Size'),
        },
        {
          key: 'created',
          label: __('Created'),
        },
        {
          key: 'actions',
          label: '',
          hide: !this.canDelete,
          thClass: 'gl-w-4',
        },
      ].filter((c) => !c.hide);
    },
    queryVariables() {
      return {
        id: this.packageId,
        first: GRAPHQL_PACKAGE_FILES_PAGE_SIZE,
      };
    },
    tracking() {
      return {
        category: packageTypeToTrackCategory(this.packageType),
      };
    },
    refetchQueriesData() {
      return [
        {
          query: getPackageFilesQuery,
          variables: this.queryVariables,
        },
      ];
    },
    modalAction() {
      return this.hasOneItem(this.filesToDelete)
        ? this.$options.modal.fileDeletePrimaryAction
        : this.$options.modal.filesDeletePrimaryAction;
    },
    modalTitle() {
      return this.hasOneItem(this.filesToDelete)
        ? this.$options.i18n.deleteFileModalTitle
        : this.$options.i18n.deleteFilesModalTitle;
    },
    modalDescription() {
      return this.hasOneItem(this.filesToDelete)
        ? this.$options.i18n.deleteFileModalContent
        : this.$options.i18n.deleteFilesModalContent;
    },
  },
  methods: {
    formatSize(size) {
      return numberToHumanSize(size);
    },
    hasDetails(item) {
      return item.fileSha256 || item.fileMd5 || item.fileSha1;
    },
    trackToggleDetails(detailsShowing) {
      if (!detailsShowing) {
        this.track(TRACKING_ACTION_EXPAND_PACKAGE_ASSET, { label: TRACKING_LABEL_PACKAGE_ASSET });
      }
    },
    updateSelectedReferences(selection) {
      this.track(SELECT_PACKAGE_FILE_TRACKING_ACTION);
      this.selectedReferences = selection;
    },
    isSelected(packageFile) {
      return this.selectedReferences.find((reference) => reference.id === packageFile.id);
    },
    handleFileDeleteSelected() {
      this.track(REQUEST_DELETE_SELECTED_PACKAGE_FILE_TRACKING_ACTION);
      this.handleFileDelete(this.selectedReferences);
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
          message: this.hasOneItem(ids)
            ? DELETE_PACKAGE_FILE_SUCCESS_MESSAGE
            : DELETE_PACKAGE_FILES_SUCCESS_MESSAGE,
          variant: VARIANT_SUCCESS,
        });
      } catch (error) {
        createAlert({
          message: this.hasOneItem(ids)
            ? DELETE_PACKAGE_FILE_ERROR_MESSAGE
            : DELETE_PACKAGE_FILES_ERROR_MESSAGE,
          variant: VARIANT_WARNING,
          captureError: true,
          error,
        });
      } finally {
        this.mutationLoading = false;
        this.filesToDelete = [];
        this.selectedReferences = [];
      }
    },
    handleFileDelete(files) {
      this.track(REQUEST_DELETE_PACKAGE_FILE_TRACKING_ACTION);
      if (!this.deleteAllFiles && files.length === this.packageFiles.length && this.isLastPage) {
        this.$emit(
          'delete-all-files',
          this.hasOneItem(files)
            ? DELETE_LAST_PACKAGE_FILE_MODAL_CONTENT
            : DELETE_ALL_PACKAGE_FILES_MODAL_CONTENT,
        );
      } else {
        this.filesToDelete = files;
        this.$refs.deleteFilesModal.show();
      }
    },
    hasOneItem(items) {
      return items.length === 1;
    },
    confirmFilesDelete() {
      if (this.hasOneItem(this.filesToDelete)) {
        this.track(DELETE_PACKAGE_FILE_TRACKING_ACTION);
      } else {
        this.track(DELETE_PACKAGE_FILES_TRACKING_ACTION);
      }
      this.deletePackageFiles(this.filesToDelete.map((file) => file.id));
    },
    fetchPreviousFilesPage() {
      return this.$apollo.queries.packageFiles
        .fetchMore({
          variables: {
            first: null,
            last: GRAPHQL_PACKAGE_FILES_PAGE_SIZE,
            before: this.pageInfo.startCursor,
          },
        })
        .then(() => {
          this.scrollAndFocus();
        });
    },
    fetchNextFilesPage() {
      return this.$apollo.queries.packageFiles
        .fetchMore({
          variables: {
            first: GRAPHQL_PACKAGE_FILES_PAGE_SIZE,
            last: null,
            after: this.pageInfo.endCursor,
          },
        })
        .then(() => {
          this.scrollAndFocus();
        });
    },
    scrollAndFocus() {
      scrollToElement(this.$el);

      // get first focusable row
      const focusable = this.$el.querySelector('tbody tr');
      if (focusable) {
        focusable.focus();
      }
    },
    refetchPackageFiles() {
      this.$apollo.getClient().refetchQueries({ include: [getPackageFilesQuery] });
    },
  },
  i18n: {
    deleteFile: s__('PackageRegistry|Delete asset'),
    deleteFileModalTitle: s__('PackageRegistry|Delete package asset'),
    deleteFileModalContent: s__(
      'PackageRegistry|You are about to delete %{filename}. This is a destructive action that may render your package unusable. Are you sure?',
    ),
    deleteFilesModalTitle: s__('PackageRegistry|Delete %{count} assets'),
    deleteFilesModalContent: s__(
      'PackageRegistry|You are about to delete %{count} assets. This operation is irreversible.',
    ),
    deleteSelected: s__('PackageRegistry|Delete selected'),
    moreActionsText: __('More actions'),
    fetchPackageFilesErrorMessage: FETCH_PACKAGE_FILES_ERROR_MESSAGE,
  },
  modal: {
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
  <div class="gl-pt-6">
    <div class="gl-flex gl-items-center gl-justify-between">
      <h3 class="gl-mt-5 gl-text-lg">{{ __('Assets') }}</h3>
      <gl-button
        v-if="!fetchPackageFilesError && canDelete"
        :disabled="isLoading || !areFilesSelected"
        category="secondary"
        variant="danger"
        data-testid="delete-selected"
        @click="handleFileDeleteSelected"
      >
        {{ $options.i18n.deleteSelected }}
      </gl-button>
    </div>
    <gl-alert
      v-if="fetchPackageFilesError"
      variant="danger"
      @dismiss="fetchPackageFilesError = false"
    >
      {{ $options.i18n.fetchPackageFilesErrorMessage }}
    </gl-alert>
    <template v-else>
      <gl-table
        ref="table"
        :busy="isLoading"
        :fields="filesTableHeaderFields"
        :items="filesTableRows"
        show-empty
        selectable
        select-mode="multi"
        selected-variant="primary"
        :tbody-tr-attr="{ 'data-testid': 'file-row' }"
        @row-selected="updateSelectedReferences"
      >
        <template #table-busy>
          <gl-loading-icon size="lg" class="gl-my-5" />
        </template>
        <template #head(checkbox)="{ selectAllRows, clearSelected }">
          <gl-form-checkbox
            v-if="canDelete"
            class="gl-min-h-0"
            data-testid="package-files-checkbox-all"
            :checked="areAllFilesSelected"
            :indeterminate="hasSelectedSomeFiles"
            @change="areAllFilesSelected ? clearSelected() : selectAllRows()"
          />
        </template>

        <template #cell(checkbox)="{ rowSelected, selectRow, unselectRow }">
          <gl-form-checkbox
            v-if="canDelete"
            :checked="rowSelected"
            class="gl-min-h-0"
            data-testid="package-files-checkbox"
            @change="rowSelected ? unselectRow() : selectRow()"
          />
        </template>

        <template #cell(name)="{ item, toggleDetails, detailsShowing }">
          <gl-button
            v-if="hasDetails(item)"
            :icon="detailsShowing ? 'chevron-up' : 'chevron-down'"
            :aria-label="detailsShowing ? __('Collapse') : __('Expand')"
            data-testid="toggle-details-button"
            category="tertiary"
            class="!-gl-mt-2"
            size="small"
            @click="
              toggleDetails();
              trackToggleDetails(detailsShowing);
            "
          />
          <gl-link
            :href="item.downloadPath"
            class="gl-text-subtle"
            data-testid="download-link"
            @click="track($options.trackingActions.DOWNLOAD_PACKAGE_ASSET_TRACKING_ACTION)"
          >
            <file-icon
              :file-name="item.fileName"
              css-classes="gl-relative file-icon"
              class="gl-relative gl-mr-1"
            />
            <span>{{ item.fileName }}</span>
          </gl-link>
        </template>

        <template #cell(created)="{ item }">
          <time-ago-tooltip :time="item.createdAt" />
        </template>

        <template #cell(actions)="{ item }">
          <gl-disclosure-dropdown
            category="tertiary"
            icon="ellipsis_v"
            placement="bottom-end"
            class="!-gl-my-3"
            :toggle-text="$options.i18n.moreActionsText"
            text-sr-only
            no-caret
          >
            <gl-disclosure-dropdown-item
              data-testid="delete-file"
              @action="handleFileDelete([item])"
            >
              <template #list-item>
                <span class="gl-text-red-500">{{ $options.i18n.deleteFile }}</span>
              </template>
            </gl-disclosure-dropdown-item>
          </gl-disclosure-dropdown>
        </template>

        <template #row-details="{ item }">
          <div
            class="gl-flex gl-grow gl-flex-col gl-rounded-base gl-bg-subtle gl-shadow-inner-1-gray-100"
          >
            <file-sha
              v-if="item.fileSha256"
              data-testid="sha-256"
              title="SHA-256"
              :sha="item.fileSha256"
            />
            <file-sha v-if="item.fileMd5" data-testid="md5" title="MD5" :sha="item.fileMd5" />
            <file-sha v-if="item.fileSha1" data-testid="sha-1" title="SHA-1" :sha="item.fileSha1" />
          </div>
        </template>
      </gl-table>
      <div class="gl-flex gl-justify-center">
        <gl-keyset-pagination
          :disabled="isLoading"
          v-bind="pageInfo"
          class="gl-mt-3"
          @prev="fetchPreviousFilesPage"
          @next="fetchNextFilesPage"
        />
      </div>
      <slot name="upload" :refetch="refetchPackageFiles"></slot>
    </template>

    <gl-modal
      ref="deleteFilesModal"
      size="sm"
      modal-id="delete-files-modal"
      :action-primary="modalAction"
      :action-cancel="$options.modal.cancelAction"
      data-testid="delete-files-modal"
      @primary="confirmFilesDelete"
      @canceled="track($options.trackingActions.CANCEL_DELETE_PACKAGE_FILE)"
    >
      <template #modal-title>
        <gl-sprintf :message="modalTitle">
          <template #count>
            {{ filesToDelete.length }}
          </template>
        </gl-sprintf>
      </template>

      <gl-sprintf :message="modalDescription">
        <template #filename>
          <strong>{{ filesToDelete[0].fileName }}</strong>
        </template>

        <template #count>
          {{ filesToDelete.length }}
        </template>
      </gl-sprintf>
    </gl-modal>
  </div>
</template>
