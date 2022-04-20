<script>
import { GlAlert } from '@gitlab/ui';
import { __, s__ } from '~/locale';
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
    FileItem,
    GlAlert,
  },
  inject: ['ciConfigPath'],
  data() {
    return {
      showTip: true,
    };
  },
  methods: {
    dismissTip() {
      this.showTip = false;
    },
  },
};
</script>
<template>
  <aside class="file-tree-container gl-mr-5 gl-mb-5">
    <file-item class="gl-mb-3 gl-bg-gray-50" :file-name="ciConfigPath" />
    <gl-alert v-if="showTip" variant="tip" :title="$options.i18n.tipTitle" @dismiss="dismissTip">
      {{ $options.i18n.tipDescription }}
    </gl-alert>
  </aside>
</template>
