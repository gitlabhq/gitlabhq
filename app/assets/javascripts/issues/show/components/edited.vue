<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { n__, sprintf } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    TimeAgoTooltip,
    GlLink,
    GlSprintf,
  },
  props: {
    taskCompletionStatus: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    updatedAt: {
      type: String,
      required: false,
      default: '',
    },
    updatedByName: {
      type: String,
      required: false,
      default: '',
    },
    updatedByPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    completedCount() {
      // The new Work Item GraphQL endpoint returns `completedCount` instead, so added a fallback
      // to it for the work item view
      return this.taskCompletionStatus.completed_count ?? this.taskCompletionStatus.completedCount;
    },
    count() {
      return this.taskCompletionStatus.count;
    },
    hasUpdatedBy() {
      return this.updatedByName && this.updatedByPath;
    },
    showCheck() {
      return this.completedCount === this.count;
    },
    taskStatus() {
      const { completedCount, count } = this;
      if (!count) {
        return undefined;
      }

      return sprintf(
        n__(
          '%{completedCount} of %{count} checklist item completed',
          '%{completedCount} of %{count} checklist items completed',
          count,
        ),
        { completedCount, count },
      );
    },
  },
};
</script>

<template>
  <small
    v-if="taskStatus || updatedAt"
    class="js-issue-widgets gl-inline-block gl-text-sm gl-text-subtle"
  >
    <template v-if="taskStatus">
      <template v-if="showCheck">&check;</template>
      {{ taskStatus }}
      <template v-if="updatedAt">&middot;</template>
    </template>

    <template v-if="updatedAt">
      <gl-sprintf v-if="!hasUpdatedBy" :message="__('Edited %{timeago}')">
        <template #timeago>
          <time-ago-tooltip :time="updatedAt" tooltip-placement="bottom" />
        </template>
      </gl-sprintf>
      <gl-sprintf v-else :message="__('Edited %{timeago} by %{author}')">
        <template #timeago>
          <time-ago-tooltip :time="updatedAt" tooltip-placement="bottom" />
        </template>
        <template #author>
          <gl-link :href="updatedByPath" class="gl-text-subtle hover:gl-text-subtle">
            {{ updatedByName }}
          </gl-link>
        </template>
      </gl-sprintf>
    </template>
  </small>
</template>
