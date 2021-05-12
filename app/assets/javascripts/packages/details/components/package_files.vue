<script>
import { GlLink, GlTable } from '@gitlab/ui';
import { last } from 'lodash';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  name: 'PackageFiles',
  components: {
    GlLink,
    GlTable,
    FileIcon,
    TimeAgoTooltip,
  },
  mixins: [Tracking.mixin()],
  props: {
    packageFiles: {
      type: Array,
      required: false,
      default: () => [],
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
          tdClass: 'gl-display-flex gl-align-items-center',
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
      ].filter((c) => !c.hide);
    },
  },
  methods: {
    formatSize(size) {
      return numberToHumanSize(size);
    },
  },
};
</script>

<template>
  <div>
    <h3 class="gl-font-lg gl-mt-5">{{ __('Files') }}</h3>
    <gl-table
      :fields="filesTableHeaderFields"
      :items="filesTableRows"
      :tbody-tr-attr="{ 'data-testid': 'file-row' }"
    >
      <template #cell(name)="{ item }">
        <gl-link
          :href="item.download_path"
          class="gl-relative gl-text-gray-500"
          data-testid="download-link"
          @click="$emit('download-file')"
        >
          <file-icon
            :file-name="item.file_name"
            css-classes="gl-relative file-icon"
            class="gl-mr-1 gl-relative"
          />
          <span class="gl-relative">{{ item.file_name }}</span>
        </gl-link>
      </template>

      <template #cell(commit)="{ item }">
        <gl-link
          v-if="item.pipeline && item.pipeline.project"
          :href="item.pipeline.project.commit_url"
          class="gl-text-gray-500"
          data-testid="commit-link"
          >{{ item.pipeline.git_commit_message }}</gl-link
        >
      </template>

      <template #cell(created)="{ item }">
        <time-ago-tooltip :time="item.created_at" />
      </template>
    </gl-table>
  </div>
</template>
