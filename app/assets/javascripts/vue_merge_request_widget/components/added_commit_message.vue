<script>
import { GlSprintf } from '@gitlab/ui';
import { escape } from 'lodash';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { n__, s__ } from '~/locale';

const mergeCommitCount = s__('mrWidgetCommitsAdded|1 merge commit');

export default {
  components: {
    GlSprintf,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    state: {
      type: String,
      required: false,
      default: '',
    },
    isSquashEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    isFastForwardEnabled: {
      type: Boolean,
      required: true,
    },
    commitsCount: {
      type: Number,
      required: false,
      default: 0,
    },
    targetBranch: {
      type: String,
      required: true,
    },
    mergeCommitSha: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    isMerged() {
      return this.state === 'merged';
    },
    targetBranchEscaped() {
      return escape(this.targetBranch);
    },
    commitsCountMessage() {
      return n__('%d commit', '%d commits', this.isSquashEnabled ? 1 : this.commitsCount);
    },
    message() {
      if (this.state === 'closed') {
        return s__('mrWidgetCommitsAdded|The changes were not merged into %{targetBranch}.');
      } else if (this.isMerged) {
        return s__(
          'mrWidgetCommitsAdded|Changes merged into %{targetBranch} with %{mergeCommitSha}%{squashedCommits}.',
        );
      }

      return this.isFastForwardEnabled
        ? s__('mrWidgetCommitsAdded|%{commitCount} will be added to %{targetBranch}.')
        : s__(
            'mrWidgetCommitsAdded|%{commitCount} and %{mergeCommitCount} will be added to %{targetBranch}%{squashedCommits}.',
          );
    },
    squashCommitMessage() {
      if (this.isMerged) {
        return s__('mergedCommitsAdded|(commits were squashed)');
      }

      return n__('(squashes %d commit)', '(squashes %d commits)', this.commitsCount);
    },
  },
  mergeCommitCount,
};
</script>

<template>
  <span>
    <gl-sprintf :message="message">
      <template #commitCount>
        <span class="commits-count-message">{{ commitsCountMessage }}</span>
      </template>
      <template #mergeCommitCount>
        <span>{{ $options.mergeCommitCount }}</span>
      </template>
      <template #targetBranch>
        <span class="label-branch">{{ targetBranchEscaped }}</span>
      </template>
      <template #squashedCommits>
        <template v-if="isSquashEnabled"> {{ squashCommitMessage }}</template>
      </template>
      <template #mergeCommitSha>
        <span class="label-branch">{{ mergeCommitSha }}</span>
      </template>
    </gl-sprintf>
  </span>
</template>
