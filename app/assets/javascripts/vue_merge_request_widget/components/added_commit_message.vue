<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { escape } from 'lodash';
import { STATUS_CLOSED, STATUS_MERGED } from '~/issues/constants';
import { n__, s__, sprintf } from '~/locale';

const mergeCommitCount = s__('mrWidgetCommitsAdded|%{strongStart}1%{strongEnd} merge commit');

export default {
  components: {
    GlSprintf,
    GlLink,
  },
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
    mergeCommitPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    isMerged() {
      return this.state === STATUS_MERGED;
    },
    targetBranchEscaped() {
      return escape(this.targetBranch);
    },
    commitsCountMessage() {
      const count = this.isSquashEnabled ? 1 : this.commitsCount;

      return sprintf(
        n__(
          '%{strongStart}%{count}%{strongEnd} commit',
          '%{strongStart}%{count}%{strongEnd} commits',
          count,
        ),
        { count },
      );
    },
    message() {
      if (this.state === STATUS_CLOSED) {
        return s__('mrWidgetCommitsAdded|The changes were not merged into %{targetBranch}.');
      }
      if (this.isMerged) {
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
        return s__('mergedCommitsAdded| (commits were squashed)');
      }

      return sprintf(
        n__(
          ' (squashes %{strongStart}%{count}%{strongEnd} commit)',
          ' (squashes %{strongStart}%{count}%{strongEnd} commits)',
          this.commitsCount,
        ),
        { count: this.commitsCount },
      );
    },
  },
  mergeCommitCount,
};
</script>

<template>
  <span>
    <gl-sprintf :message="message">
      <template #commitCount>
        <gl-sprintf :message="commitsCountMessage">
          <template #strong="{ content }">
            <span class="gl-font-bold">{{ content }}</span>
          </template>
        </gl-sprintf>
      </template>
      <template #mergeCommitCount>
        <gl-sprintf :message="$options.mergeCommitCount">
          <template #strong="{ content }">
            <span class="gl-font-bold">{{ content }}</span>
          </template>
        </gl-sprintf>
      </template>
      <template #targetBranch>
        <span class="label-branch gl-font-bold">{{ targetBranchEscaped }}</span>
      </template>
      <template #squashedCommits>
        <template v-if="isSquashEnabled">
          <gl-sprintf :message="squashCommitMessage">
            <template #strong="{ content }">
              <span class="gl-font-bold">{{ content }}</span>
            </template>
          </gl-sprintf>
        </template>
      </template>
      <template #mergeCommitSha>
        <gl-link :href="mergeCommitPath" class="label-branch" data-testid="merge-commit-sha">{{
          mergeCommitSha
        }}</gl-link>
      </template>
    </gl-sprintf>
  </span>
</template>
