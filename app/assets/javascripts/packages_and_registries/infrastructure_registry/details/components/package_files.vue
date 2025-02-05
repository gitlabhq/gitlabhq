<script>
import {
  GlLink,
  GlTable,
  GlDisclosureDropdownItem,
  GlDisclosureDropdown,
  GlButton,
} from '@gitlab/ui';
import { last } from 'lodash';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import FileSha from './file_sha.vue';

export default {
  name: 'PackageFiles',
  components: {
    GlLink,
    GlTable,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlButton,
    FileIcon,
    TimeAgoTooltip,
    FileSha,
  },
  mixins: [Tracking.mixin()],
  props: {
    packageFiles: {
      type: Array,
      required: false,
      default: () => [],
    },
    canDelete: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  computed: {
    filesTableRows() {
      return this.packageFiles.map((pf) => ({
        ...pf,
        size: this.formatSize(pf.size),
        pipeline: last(pf.pipelines),
      }));
    },
    showCommitColumn() {
      return this.filesTableRows.some((row) => Boolean(row.pipeline?.id));
    },
    filesTableHeaderFields() {
      return [
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
          tdClass: 'gl-w-4',
        },
      ].filter((c) => !c.hide);
    },
  },
  methods: {
    formatSize(size) {
      return numberToHumanSize(size);
    },
    hasDetails(item) {
      return item.file_sha256 || item.file_md5 || item.file_sha1;
    },
  },
  i18n: {
    deleteFile: __('Delete asset'),
  },
};
</script>

<template>
  <div>
    <h3 class="gl-mt-5 gl-text-lg">{{ __('Assets') }}</h3>
    <gl-table
      :fields="filesTableHeaderFields"
      :items="filesTableRows"
      :tbody-tr-attr="{ 'data-testid': 'file-row' }"
    >
      <template #cell(name)="{ item, toggleDetails, detailsShowing }">
        <gl-button
          v-if="hasDetails(item)"
          :icon="detailsShowing ? 'chevron-lg-up' : 'chevron-lg-down'"
          :aria-label="detailsShowing ? __('Collapse') : __('Expand')"
          category="tertiary"
          size="small"
          @click="toggleDetails"
        />
        <gl-link
          :href="item.download_path"
          class="gl-text-subtle"
          data-testid="download-link"
          @click="$emit('download-file')"
        >
          <file-icon
            :file-name="item.file_name"
            css-classes="gl-relative file-icon"
            class="gl-relative gl-mr-1"
          />
          <span>{{ item.file_name }}</span>
        </gl-link>
      </template>

      <template #cell(commit)="{ item }">
        <gl-link
          v-if="item.pipeline && item.pipeline.project"
          :href="item.pipeline.project.commit_url"
          class="gl-text-subtle"
          data-testid="commit-link"
          >{{ item.pipeline.git_commit_message }}</gl-link
        >
      </template>

      <template #cell(created)="{ item }">
        <time-ago-tooltip :time="item.created_at" />
      </template>

      <template #cell(actions)="{ item }">
        <gl-disclosure-dropdown category="tertiary" right no-caret icon="ellipsis_v">
          <gl-disclosure-dropdown-item
            data-testid="delete-file"
            @action="$emit('delete-file', item)"
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
            v-if="item.file_sha256"
            data-testid="sha-256"
            title="SHA-256"
            :sha="item.file_sha256"
          />
          <file-sha v-if="item.file_md5" data-testid="md5" title="MD5" :sha="item.file_md5" />
          <file-sha v-if="item.file_sha1" data-testid="sha-1" title="SHA-1" :sha="item.file_sha1" />
        </div>
      </template>
    </gl-table>
  </div>
</template>
