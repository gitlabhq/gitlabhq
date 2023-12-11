<script>
import { GlTableLite } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { formatTime } from '~/lib/utils/datetime_utility';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import RunnerTags from '~/ci/runner/components/runner_tags.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { tableField } from '../utils';
import LinkCell from './cells/link_cell.vue';

export default {
  components: {
    CiIcon,
    GlTableLite,
    LinkCell,
    RunnerTags,
    TimeAgo,
  },
  props: {
    jobs: {
      type: Array,
      required: true,
    },
  },
  methods: {
    trAttr(job) {
      if (job?.id) {
        return { 'data-testid': `job-row-${getIdFromGraphQLId(job.id)}` };
      }
      return {};
    },
    jobId(job) {
      return getIdFromGraphQLId(job.id);
    },
    jobPath(job) {
      return job.detailedStatus?.detailsPath;
    },
    projectName(job) {
      return job.project?.name;
    },
    projectWebUrl(job) {
      return job.project?.webUrl;
    },
    commitShortSha(job) {
      return job.shortSha;
    },
    commitPath(job) {
      return job.commitPath;
    },
    duration(job) {
      const { duration } = job;
      return duration ? formatTime(duration * 1000) : '';
    },
    queued(job) {
      const { queuedDuration } = job;
      return queuedDuration ? formatTime(queuedDuration * 1000) : '';
    },
  },
  fields: [
    tableField({ key: 'status', label: s__('Job|Status') }),
    tableField({ key: 'job', label: __('Job') }),
    tableField({ key: 'project', label: __('Project') }),
    tableField({ key: 'commit', label: __('Commit') }),
    tableField({ key: 'finished_at', label: s__('Job|Finished at') }),
    tableField({ key: 'duration', label: s__('Job|Duration') }),
    tableField({ key: 'queued', label: s__('Job|Queued') }),
    tableField({ key: 'tags', label: s__('Runners|Tags') }),
  ],
};
</script>

<template>
  <gl-table-lite
    :items="jobs"
    :fields="$options.fields"
    :tbody-tr-attr="trAttr"
    primary-key="id"
    stacked="md"
    fixed
  >
    <template #cell(status)="{ item = {} }">
      <ci-icon v-if="item.detailedStatus" :status="item.detailedStatus" show-status-text />
    </template>

    <template #cell(job)="{ item = {} }">
      <link-cell :href="jobPath(item)"> #{{ jobId(item) }} </link-cell>
    </template>

    <template #cell(project)="{ item = {} }">
      <link-cell :href="projectWebUrl(item)">{{ projectName(item) }}</link-cell>
    </template>

    <template #cell(commit)="{ item = {} }">
      <link-cell :href="commitPath(item)"> {{ commitShortSha(item) }}</link-cell>
    </template>

    <template #cell(finished_at)="{ item = {} }">
      <time-ago v-if="item.finishedAt" :time="item.finishedAt" />
    </template>

    <template #cell(duration)="{ item = {} }">
      {{ duration(item) }}
    </template>

    <template #cell(queued)="{ item = {} }">
      {{ queued(item) }}
    </template>

    <template #cell(tags)="{ item = {} }">
      <runner-tags :tag-list="item.tags" />
    </template>
  </gl-table-lite>
</template>
