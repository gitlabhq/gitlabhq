<script l>
import { GlAnimatedChevronLgDownUpIcon, GlButton, GlTooltipDirective } from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { __ } from '~/locale';

export default {
  name: 'CommitListItemActionButtons',
  components: { ClipboardButton, GlButton, GlAnimatedChevronLgDownUpIcon },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    commit: {
      type: Object,
      required: true,
    },
    isCollapsed: {
      type: Boolean,
      required: true,
    },
    anchorId: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    toggleLabel() {
      return this.isCollapsed ? __('Expand') : __('Collapse');
    },
    ariaExpandedAttr() {
      return this.isCollapsed ? 'false' : 'true';
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-items-center">
    <gl-button
      label
      class="-gl-mr-2 !gl-bg-transparent gl-font-monospace dark:!gl-bg-strong"
      category="tertiary"
      size="small"
      >{{ commit.shortId }}
    </gl-button>
    <clipboard-button
      :text="commit.sha"
      :title="__('Copy commit SHA')"
      category="tertiary"
      size="small"
    />
    <gl-button
      category="tertiary"
      size="small"
      icon="folder-open"
      :href="commit.webUrl"
      :aria-label="__('Browse commit files')"
      class="gl-ml-5 gl-mr-4"
    />
    <div class="gl-border-l gl-border-l-section">
      <gl-button
        v-gl-tooltip
        :aria-label="toggleLabel"
        :aria-expanded="ariaExpandedAttr"
        :aria-controls="anchorId"
        category="tertiary"
        size="small"
        class="-gl-mr-2 gl-ml-3 !gl-p-0"
        @click="$emit('click')"
      >
        <gl-animated-chevron-lg-down-up-icon :is-on="!isCollapsed" variant="default" />
      </gl-button>
    </div>
  </div>
</template>
