<script>
import { GlAlert, GlTooltipDirective } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import { FILE_TREE_TIP_DISMISSED_KEY } from '../../constants';
import FileItem from './file_item.vue';

const i18n = {
  tipBtn: __('Learn more'),
  tipDescription: s__(
    'PipelineEditorFileTree|When you use the include keyword to add pipeline configuration from files in the project, those files will be listed here.',
  ),
  tipTitle: s__('PipelineEditorFileTree|Configuration files added with the include keyword'),
};

export default {
  i18n,
  name: 'PipelineEditorFileTreeContainer',
  components: {
    FileIcon,
    FileItem,
    GlAlert,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['ciConfigPath', 'includesHelpPagePath'],
  props: {
    includes: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      canShowTip: localStorage.getItem(FILE_TREE_TIP_DISMISSED_KEY) !== 'true',
    };
  },
  computed: {
    showTip() {
      return this.includes.length === 0 && this.canShowTip;
    },
  },
  methods: {
    dismissTip() {
      this.canShowTip = false;
      localStorage.setItem(FILE_TREE_TIP_DISMISSED_KEY, 'true');
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
    <gl-alert
      v-if="showTip"
      variant="tip"
      :title="$options.i18n.tipTitle"
      :secondary-button-text="$options.i18n.tipBtn"
      :secondary-button-link="includesHelpPagePath"
      @dismiss="dismissTip"
    >
      {{ $options.i18n.tipDescription }}
    </gl-alert>
    <div class="gl-overflow-y-auto">
      <file-item v-for="file in includes" :key="file.location" :file="file" />
    </div>
  </aside>
</template>
