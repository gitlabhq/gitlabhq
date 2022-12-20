<script>
import { GlLabel, GlAvatar, GlAvatarLink, GlAvatarsInline, GlTooltipDirective } from '@gitlab/ui';

import { s__, sprintf } from '~/locale';
import { isScopedLabel } from '~/lib/utils/common_utils';

import ItemMilestone from '~/issuable/components/issue_milestone.vue';

export default {
  components: {
    GlLabel,
    GlAvatar,
    GlAvatarLink,
    GlAvatarsInline,
    ItemMilestone,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    allowsScopedLabels: {
      type: Boolean,
      required: false,
      default: false,
    },
    milestone: {
      type: Object,
      required: false,
      default: null,
    },
    assignees: {
      type: Array,
      required: false,
      default: () => [],
    },
    labels: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    assigneesCollapsedTooltip() {
      if (this.assignees.length > 2) {
        return sprintf(s__('WorkItem|%{count} more assignees'), {
          count: this.assignees.length - 2,
        });
      }
      return '';
    },
    assigneesContainerClass() {
      if (this.assignees.length === 2) {
        return 'fixed-width-avatars-2';
      } else if (this.assignees.length > 2) {
        return 'fixed-width-avatars-3';
      }
      return '';
    },
    labelsContainerClass() {
      if (this.milestone || this.assignees.length) {
        return 'gl-sm-ml-5';
      }
      return '';
    },
  },
  methods: {
    showScopedLabel(label) {
      return isScopedLabel(label) && this.allowsScopedLabels;
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-flex-wrap gl-align-items-center">
    <item-milestone
      v-if="milestone"
      :milestone="milestone"
      class="gl-display-flex gl-align-items-center gl-mr-5 gl-max-w-15 gl-text-secondary! gl-cursor-help! gl-text-decoration-none!"
    />
    <gl-avatars-inline
      v-if="assignees.length"
      :avatars="assignees"
      :collapsed="true"
      :max-visible="2"
      :avatar-size="24"
      badge-tooltip-prop="name"
      :badge-sr-only-text="assigneesCollapsedTooltip"
      :class="assigneesContainerClass"
    >
      <template #avatar="{ avatar }">
        <gl-avatar-link v-gl-tooltip target="blank" :href="avatar.webUrl" :title="avatar.name">
          <gl-avatar :src="avatar.avatarUrl" :size="24" />
        </gl-avatar-link>
      </template>
    </gl-avatars-inline>
    <div v-if="labels.length" class="gl-display-flex gl-flex-wrap" :class="labelsContainerClass">
      <gl-label
        v-for="label in labels"
        :key="label.id"
        :title="label.title"
        :background-color="label.color"
        :description="label.description"
        :scoped="showScopedLabel(label)"
        class="gl-mt-2 gl-sm-mt-0 gl-mr-2 gl-mb-auto gl-label-sm"
        tooltip-placement="top"
      />
    </div>
  </div>
</template>

<style scoped>
/**
 * These overrides are needed to address https://gitlab.com/gitlab-org/gitlab-ui/-/issues/865
 */
.fixed-width-avatars-2 {
  width: 42px !important;
}

.fixed-width-avatars-3 {
  width: 67px !important;
}
</style>
