<script l>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ExpandCollapseButton from '~/vue_shared/components/expand_collapse_button/expand_collapse_button.vue';
import { joinPaths } from '~/lib/utils/url_utility';
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
  inject: ['projectRootPath'],
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
    browseFilesPath() {
      return joinPaths(this.projectRootPath, '-', 'tree', this.commit.sha);
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
      v-gl-tooltip
      category="tertiary"
      size="small"
      icon="folder-open"
      :href="browseFilesPath"
      :title="__('Browse commit files')"
      :aria-label="__('Browse commit files')"
      class="gl-ml-5"
      data-testid="browse-files-button"
    />
    <div
      class="gl-border-l gl-ml-4 gl-border-l-section"
      :class="{ 'gl-invisible': !commit.description }"
    >
      <expand-collapse-button
        :is-collapsed="isCollapsed"
        :anchor-id="anchorId"
        :accessible-label="commit.titleHtml"
        @click="$emit('click')"
      />
    </div>
  </div>
</template>
