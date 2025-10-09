<script l>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ExpandCollapseButton from '~/vue_shared/components/expand_collapse_button/expand_collapse_button.vue';
import { __, sprintf } from '~/locale';

export default {
  name: 'CommitListItemActionButtons',
  components: {
    ExpandCollapseButton,
    ClipboardButton,
    GlButton,
  },
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
    copyCommitShaTitle() {
      return sprintf(__('Copy commit SHA %{sha}'), { sha: this.commit.sha });
    },
  },
};
</script>

<template>
  <div class="gl-hidden gl-items-center @md/panel:gl-flex">
    <span class="gl-mr-2 gl-font-monospace">{{ commit.shortId }}</span>
    <clipboard-button
      :text="commit.sha"
      :title="copyCommitShaTitle"
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
      data-testid="browse-files-button"
    />
    <div class="gl-border-l gl-border-l-section">
      <expand-collapse-button
        :is-collapsed="isCollapsed"
        :anchor-id="anchorId"
        :accessible-label="commit.titleHtml"
        @click="$emit('click')"
      />
    </div>
  </div>
</template>
