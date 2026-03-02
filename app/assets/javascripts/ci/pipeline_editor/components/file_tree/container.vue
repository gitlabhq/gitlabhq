<script>
import { GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import FileItem from './file_item.vue';

const i18n = {
  emptyStateText: s__(
    'PipelineEditorFileTree|When you add configuration files by using %{codeStart}include%{codeEnd}, they appear in this list.',
  ),
};

export default {
  i18n,
  name: 'PipelineEditorFileTreeContainer',
  components: {
    FileIcon,
    FileItem,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['ciConfigPath'],
  props: {
    includes: {
      type: Array,
      required: true,
    },
  },
};
</script>
<template>
  <aside class="file-tree-container gl-mb-5 gl-mr-5">
    <div
      v-gl-tooltip
      :title="ciConfigPath"
      class="gl-mb-3 gl-rounded-base gl-bg-strong gl-px-3 gl-py-2"
    >
      <span class="file-row-name gl-str-truncated" :title="ciConfigPath">
        <file-icon class="file-row-icon" :file-name="ciConfigPath" />
        <span data-testid="current-config-filename">{{ ciConfigPath }}</span>
      </span>
    </div>
    <div v-if="includes.length === 0" class="gl-py-3 gl-text-subtle" data-testid="empty-state-text">
      <gl-sprintf :message="$options.i18n.emptyStateText">
        <template #code="{ content }">
          <code>{{ content }}</code>
        </template>
      </gl-sprintf>
    </div>
    <div class="gl-overflow-y-auto">
      <file-item v-for="file in includes" :key="file.location" :file="file" />
    </div>
  </aside>
</template>
