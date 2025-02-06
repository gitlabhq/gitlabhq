<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { VALID_DESIGN_FILE_MIMETYPE } from './constants';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    isSaving: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    openFileUpload() {
      this.$refs.fileUpload.click();
    },
    onFileUploadChange(e) {
      this.$emit('upload', e.target.files);
    },
  },
  VALID_DESIGN_FILE_MIMETYPE,
};
</script>

<template>
  <div class="sm:gl-ml-auto">
    <gl-button
      v-gl-tooltip.hover
      :title="
        s__(
          'DesignManagement|Adding a design with the same filename replaces the file in a new version.',
        )
      "
      :disabled="isSaving"
      :loading="isSaving"
      category="primary"
      icon="media"
      @click="openFileUpload"
    >
      {{ s__('DesignManagement|Add design') }}
    </gl-button>

    <input
      ref="fileUpload"
      type="file"
      name="design_file"
      :accept="$options.VALID_DESIGN_FILE_MIMETYPE.mimetype"
      class="gl-hidden"
      multiple
      @change="onFileUploadChange"
    />
  </div>
</template>
