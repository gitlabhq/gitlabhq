<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import AddedCommitMessage from '../added_commit_message.vue';

export default {
  components: {
    GlButton,
    AddedCommitMessage,
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
    modifyLinkMessage() {
      if (this.isFastForwardEnabled) return __('Modify commit message');
      if (this.isSquashEnabled) return __('Modify commit messages');
      return __('Modify merge commit');
    },
    ariaLabel() {
      return this.expanded ? __('Collapse') : __('Expand');
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
      class="js-mr-widget-commits-count mr-widget-extension clickable px-3 py-2 gl-flex gl-items-center"
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
          <added-commit-message
            :is-squash-enabled="isSquashEnabled"
            :is-fast-forward-enabled="isFastForwardEnabled"
            :commits-count="commitsCount"
            :target-branch="targetBranch"
          />
        </span>
        <gl-button category="tertiary" variant="confirm" size="small" class="modify-message-button">
          {{ modifyLinkMessage }}
        </gl-button>
      </span>
    </div>
    <div v-show="expanded"><slot></slot></div>
  </div>
</template>
