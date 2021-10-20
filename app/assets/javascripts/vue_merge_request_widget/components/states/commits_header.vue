<script>
import { GlButton, GlSprintf } from '@gitlab/ui';
import { escape } from 'lodash';
import { __, n__, s__ } from '~/locale';

const mergeCommitCount = s__('mrWidgetCommitsAdded|1 merge commit');

export default {
  mergeCommitCount,
  components: {
    GlButton,
    GlSprintf,
  },
  props: {
    isSquashEnabled: {
      type: Boolean,
      required: true,
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
  data() {
    return {
      expanded: false,
    };
  },
  computed: {
    collapseIcon() {
      return this.expanded ? 'chevron-down' : 'chevron-right';
    },
    commitsCountMessage() {
      return n__('%d commit', '%d commits', this.isSquashEnabled ? 1 : this.commitsCount);
    },
    modifyLinkMessage() {
      if (this.isFastForwardEnabled) return __('Modify commit message');
      else if (this.isSquashEnabled) return __('Modify commit messages');
      return __('Modify merge commit');
    },
    ariaLabel() {
      return this.expanded ? __('Collapse') : __('Expand');
    },
    targetBranchEscaped() {
      return escape(this.targetBranch);
    },
    message() {
      return this.isFastForwardEnabled
        ? s__('mrWidgetCommitsAdded|%{commitCount} will be added to %{targetBranch}.')
        : s__(
            'mrWidgetCommitsAdded|%{commitCount} and %{mergeCommitCount} will be added to %{targetBranch}.',
          );
    },
  },
  methods: {
    toggle() {
      this.expanded = !this.expanded;
    },
  },
};
</script>

<template>
  <div>
    <div
      class="js-mr-widget-commits-count mr-widget-extension clickable d-flex align-items-center px-3 py-2"
      @click="toggle()"
    >
      <gl-button
        :aria-label="ariaLabel"
        category="tertiary"
        class="commit-edit-toggle gl-mr-3"
        size="small"
        :icon="collapseIcon"
        @click.stop="toggle()"
      />
      <span v-if="expanded">{{ __('Collapse') }}</span>
      <span v-else>
        <span class="vertical-align-middle">
          <gl-sprintf :message="message">
            <template #commitCount>
              <strong class="commits-count-message">{{ commitsCountMessage }}</strong>
            </template>
            <template #mergeCommitCount>
              <strong>{{ $options.mergeCommitCount }}</strong>
            </template>
            <template #targetBranch>
              <span class="label-branch">{{ targetBranchEscaped }}</span>
            </template>
          </gl-sprintf>
        </span>
        <gl-button variant="link" class="modify-message-button">
          {{ modifyLinkMessage }}
        </gl-button>
      </span>
    </div>
    <div v-show="expanded"><slot></slot></div>
  </div>
</template>
