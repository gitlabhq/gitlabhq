<script>
import { GlLink, GlTable, GlDropdownItem, GlDropdown, GlButton, GlFormCheckbox } from '@gitlab/ui';
import { last } from 'lodash';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { __, s__ } from '~/locale';
import FileSha from '~/packages_and_registries/package_registry/components/details/file_sha.vue';
import Tracking from '~/tracking';
import { packageTypeToTrackCategory } from '~/packages_and_registries/package_registry/utils';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import {
  REQUEST_DELETE_SELECTED_PACKAGE_FILE_TRACKING_ACTION,
  SELECT_PACKAGE_FILE_TRACKING_ACTION,
  TRACKING_LABEL_PACKAGE_ASSET,
  TRACKING_ACTION_EXPAND_PACKAGE_ASSET,
} from '~/packages_and_registries/package_registry/constants';

export default {
  name: 'PackageFiles',
  components: {
    GlLink,
    GlTable,
    GlDropdown,
    GlDropdownItem,
    GlFormCheckbox,
    GlButton,
    FileIcon,
    TimeAgoTooltip,
    FileSha,
  },
  mixins: [Tracking.mixin()],
  props: {
    canDelete: {
      type: Boolean,
      required: false,
      default: false,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    packageFiles: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      selectedReferences: [],
    };
  },
  computed: {
    areFilesSelected() {
      return this.selectedReferences.length > 0;
    },
    areAllFilesSelected() {
      return this.packageFiles.every(this.isSelected);
    },
    filesTableRows() {
      return this.packageFiles.map((pf) => ({
        ...pf,
        size: this.formatSize(pf.size),
        pipeline: last(pf.pipelines),
      }));
    },
    hasSelectedSomeFiles() {
      return this.areFilesSelected && !this.areAllFilesSelected;
    },
    showCommitColumn() {
      // note that this is always false for now since we do not return
      // pipelines associated to files for performance concerns
      return this.filesTableRows.some((row) => Boolean(row.pipeline?.id));
    },
    filesTableHeaderFields() {
      return [
        {
          key: 'checkbox',
          label: __('Select all'),
          class: 'gl-w-4',
          hide: !this.canDelete,
        },
        {
          key: 'name',
          label: __('Name'),
        },
        {
          key: 'commit',
          label: __('Commit'),
          hide: !this.showCommitColumn,
        },
        {
          key: 'size',
          label: __('Size'),
        },
        {
          key: 'created',
          label: __('Created'),
          class: 'gl-text-right',
        },
        {
          key: 'actions',
          label: '',
          hide: !this.canDelete,
          class: 'gl-text-right',
          tdClass: 'gl-w-4 gl-pt-3!',
        },
      ].filter((c) => !c.hide);
    },
    tracking() {
      return {
        category: packageTypeToTrackCategory(this.packageType),
      };
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
      this.$emit('delete-files', this.selectedReferences);
    },
  },
  i18n: {
    deleteFile: __('Delete asset'),
    deleteSelected: s__('PackageRegistry|Delete selected'),
    moreActionsText: __('More actions'),
  },
};
</script>

<template>
  <div class="gl-pt-6">
    <div class="gl-display-flex gl-align-items-center gl-justify-content-space-between">
      <h3 class="gl-font-lg gl-mt-5">{{ __('Assets') }}</h3>
      <gl-button
        v-if="canDelete"
        :disabled="isLoading || !areFilesSelected"
        category="secondary"
        variant="danger"
        data-testid="delete-selected"
        @click="handleFileDeleteSelected"
      >
        {{ $options.i18n.deleteSelected }}
      </gl-button>
    </div>
    <gl-table
      :fields="filesTableHeaderFields"
      :items="filesTableRows"
      show-empty
      selectable
      select-mode="multi"
      selected-variant="primary"
      :tbody-tr-attr="{ 'data-testid': 'file-row' }"
      @row-selected="updateSelectedReferences"
    >
      <template #head(checkbox)="{ selectAllRows, clearSelected }">
        <gl-form-checkbox
          v-if="canDelete"
          data-testid="package-files-checkbox-all"
          :checked="areAllFilesSelected"
          :indeterminate="hasSelectedSomeFiles"
          @change="areAllFilesSelected ? clearSelected() : selectAllRows()"
        />
      </template>

      <template #cell(checkbox)="{ rowSelected, selectRow, unselectRow }">
        <gl-form-checkbox
          v-if="canDelete"
          class="gl-mt-1"
          :checked="rowSelected"
          data-testid="package-files-checkbox"
          @change="rowSelected ? unselectRow() : selectRow()"
        />
      </template>

      <template #cell(name)="{ item, toggleDetails, detailsShowing }">
        <gl-button
          v-if="hasDetails(item)"
          :icon="detailsShowing ? 'chevron-up' : 'chevron-down'"
          :aria-label="detailsShowing ? __('Collapse') : __('Expand')"
          category="tertiary"
          size="small"
          @click="
            toggleDetails();
            trackToggleDetails(detailsShowing);
          "
        />
        <gl-link
          :href="item.downloadPath"
          class="gl-text-gray-500"
          data-testid="download-link"
          @click="$emit('download-file')"
        >
          <file-icon
            :file-name="item.fileName"
            css-classes="gl-relative file-icon"
            class="gl-mr-1 gl-relative"
          />
          <span>{{ item.fileName }}</span>
        </gl-link>
      </template>

      <template #cell(commit)="{ item }">
        <gl-link
          v-if="item.pipeline && item.pipeline"
          :href="item.pipeline.commitPath"
          class="gl-text-gray-500"
          data-testid="commit-link"
          >{{ item.pipeline.sha }}
        </gl-link>
      </template>

      <template #cell(created)="{ item }">
        <time-ago-tooltip :time="item.createdAt" />
      </template>

      <template #cell(actions)="{ item }">
        <gl-dropdown
          category="tertiary"
          icon="ellipsis_v"
          :text-sr-only="true"
          :text="$options.i18n.moreActionsText"
          no-caret
          right
        >
          <gl-dropdown-item data-testid="delete-file" @click="$emit('delete-files', [item])">
            {{ $options.i18n.deleteFile }}
          </gl-dropdown-item>
        </gl-dropdown>
      </template>

      <template #row-details="{ item }">
        <div
          class="gl-display-flex gl-flex-direction-column gl-flex-grow-1 gl-bg-gray-10 gl-rounded-base gl-inset-border-1-gray-100"
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
  </div>
</template>
