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
      if (this.glFeatures.restructuredMrWidget) {
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
      }

      return this.isFastForwardEnabled
        ? s__('mrWidgetCommitsAdded|Adds %{commitCount} to %{targetBranch}.')
        : s__(
            'mrWidgetCommitsAdded|Adds %{commitCount} and %{mergeCommitCount} to %{targetBranch}%{squashedCommits}.',
          );
    },
    textDecorativeComponent() {
      return this.glFeatures.restructuredMrWidget ? 'span' : 'strong';
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
        <component :is="textDecorativeComponent" class="commits-count-message">{{
          commitsCountMessage
        }}</component>
      </template>
      <template #mergeCommitCount>
        <component :is="textDecorativeComponent">{{ $options.mergeCommitCount }}</component>
      </template>
      <template #targetBranch>
        <span class="label-branch">{{ targetBranchEscaped }}</span>
      </template>
      <template #squashedCommits>
        <template v-if="glFeatures.restructuredMrWidget && isSquashEnabled">
          {{ squashCommitMessage }}</template
        ></template
      >
      <template #mergeCommitSha>
        <template v-if="glFeatures.restructuredMrWidget"
          ><span class="label-branch">{{ mergeCommitSha }}</span></template
        >
      </template>
    </gl-sprintf>
  </span>
</template>
