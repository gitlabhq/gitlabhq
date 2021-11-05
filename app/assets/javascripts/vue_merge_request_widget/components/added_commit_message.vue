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
  },
  computed: {
    targetBranchEscaped() {
      return escape(this.targetBranch);
    },
    commitsCountMessage() {
      return n__('%d commit', '%d commits', this.isSquashEnabled ? 1 : this.commitsCount);
    },
    message() {
      return this.isFastForwardEnabled
        ? s__('mrWidgetCommitsAdded|%{commitCount} will be added to %{targetBranch}.')
        : s__(
            'mrWidgetCommitsAdded|%{commitCount} and %{mergeCommitCount} will be added to %{targetBranch}%{squashedCommits}.',
          );
    },
    textDecorativeComponent() {
      return this.glFeatures.restructuredMrWidget ? 'span' : 'strong';
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
          {{ __('(commits will be squashed)') }}</template
        ></template
      >
    </gl-sprintf>
  </span>
</template>
