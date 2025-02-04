<script>
import { GlBadge, GlSprintf, GlLink, GlTooltipDirective } from '@gitlab/ui';
import {
  DETACHED_EVENT_TYPE,
  AUTO_DEVOPS_SOURCE,
  SCHEDULE_SOURCE,
  MERGE_TRAIN_EVENT_TYPE,
  MERGED_RESULT_EVENT_TYPE,
} from '../constants';

export default {
  name: 'HeaderBadges',
  components: {
    GlBadge,
    GlSprintf,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isScheduledPipeline() {
      return this.pipeline.source === SCHEDULE_SOURCE;
    },
    mergeRequestEventType() {
      return this.pipeline.mergeRequestEventType;
    },
    isMergeTrainPipeline() {
      return this.mergeRequestEventType === MERGE_TRAIN_EVENT_TYPE;
    },
    isMergedResultsPipeline() {
      return this.mergeRequestEventType === MERGED_RESULT_EVENT_TYPE;
    },
    isDetachedPipeline() {
      return this.mergeRequestEventType === DETACHED_EVENT_TYPE;
    },
    failureReason() {
      return this.pipeline.failureReason;
    },
    hasPipelineErrorMessages() {
      return this.pipeline?.errorMessages?.nodes?.length;
    },
    isAutoDevopsPipeline() {
      return this.pipeline.configSource === AUTO_DEVOPS_SOURCE;
    },
    yamlErrorMessage() {
      return this.pipeline?.errorMessages.nodes[0].content || '';
    },
    triggeredByPath() {
      return this.pipeline?.triggeredByPath;
    },
    badges() {
      return {
        schedule: this.isScheduledPipeline,
        trigger: this.pipeline.trigger,
        invalid: this.hasPipelineErrorMessages,
        child: this.pipeline.child,
        latest: this.pipeline.latest,
        mergeTrainPipeline: this.isMergeTrainPipeline,
        mergedResultsPipeline: this.isMergedResultsPipeline,
        detached: this.isDetachedPipeline,
        failed: Boolean(this.failureReason),
        autoDevops: this.isAutoDevopsPipeline,
        stuck: this.pipeline.stuck,
      };
    },
  },
};
</script>

<template>
  <div class="gl-mb-3 gl-inline-block">
    <gl-badge
      v-if="badges.schedule"
      v-gl-tooltip
      :title="__('This pipeline was created by a schedule')"
      variant="info"
    >
      {{ s__('Pipelines|Scheduled') }}
    </gl-badge>
    <gl-badge
      v-if="badges.trigger"
      v-gl-tooltip
      :title="__('This pipeline was created by an API call authenticated with a trigger token')"
      variant="info"
    >
      {{ __('trigger token') }}
    </gl-badge>
    <gl-badge
      v-if="badges.child"
      v-gl-tooltip
      :title="__('This is a child pipeline within the parent pipeline')"
      variant="info"
    >
      <gl-sprintf :message="s__('Pipelines|Child pipeline (%{linkStart}parent%{linkEnd})')">
        <template #link="{ content }">
          <gl-link :href="triggeredByPath" target="_blank">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </gl-badge>
    <gl-badge
      v-if="badges.latest"
      v-gl-tooltip
      :title="__('Latest pipeline for the most recent commit on this branch')"
      variant="success"
    >
      {{ s__('Pipelines|latest') }}
    </gl-badge>
    <gl-badge
      v-if="badges.mergeTrainPipeline"
      v-gl-tooltip
      :title="
        s__(
          'Pipelines|This pipeline ran on the contents of the merge request combined with the contents of all other merge requests queued for merging into the target branch.',
        )
      "
      variant="info"
    >
      {{ s__('Pipelines|merge train') }}
    </gl-badge>
    <gl-badge v-if="badges.invalid" v-gl-tooltip :title="yamlErrorMessage" variant="danger">
      {{ s__('Pipelines|yaml invalid') }}
    </gl-badge>
    <gl-badge v-if="badges.failed" v-gl-tooltip :title="failureReason" variant="danger">
      {{ s__('Pipelines|error') }}
    </gl-badge>
    <gl-badge
      v-if="badges.autoDevops"
      v-gl-tooltip
      :title="
        __('This pipeline makes use of a predefined CI/CD configuration enabled by Auto DevOps.')
      "
      variant="info"
    >
      {{ s__('Pipelines|Auto DevOps') }}
    </gl-badge>
    <gl-badge
      v-if="badges.detached"
      v-gl-tooltip
      :title="
        s__(
          'Pipelines|This pipeline ran on the contents of the merge requests source branch, not the target branch.',
        )
      "
      variant="info"
    >
      {{ s__('Pipelines|merge request') }}
    </gl-badge>
    <gl-badge
      v-if="badges.mergedResultsPipeline"
      v-gl-tooltip
      :title="
        s__(
          'Pipelines|This pipeline ran on the contents of the merge request combined with the contents of the target branch.',
        )
      "
      variant="info"
    >
      {{ s__('Pipelines|merged results') }}
    </gl-badge>
    <gl-badge
      v-if="badges.stuck"
      v-gl-tooltip
      :title="s__('Pipelines|This pipeline is stuck')"
      variant="warning"
    >
      {{ s__('Pipelines|stuck') }}
    </gl-badge>
  </div>
</template>
