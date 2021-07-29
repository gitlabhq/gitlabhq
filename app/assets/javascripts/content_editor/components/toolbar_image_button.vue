<script>
import {
  GlDropdown,
  GlDropdownForm,
  GlButton,
  GlFormInputGroup,
  GlDropdownDivider,
  GlDropdownItem,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { acceptedMimes } from '../extensions/image';
import { getImageAlt } from '../services/utils';

export default {
  components: {
    GlDropdown,
    GlDropdownForm,
    GlFormInputGroup,
    GlDropdownDivider,
    GlDropdownItem,
    GlButton,
  },
  directives: {
    GlTooltip,
  },
  inject: ['tiptapEditor'],
  data() {
    return {
      imgSrc: '',
    };
  },
  methods: {
    resetFields() {
      this.imgSrc = '';
      this.$refs.fileSelector.value = '';
    },
    insertImage() {
      this.tiptapEditor
        .chain()
        .focus()
        .setImage({
          src: this.imgSrc,
          canonicalSrc: this.imgSrc,
          alt: getImageAlt(this.imgSrc),
        })
        .run();

      this.resetFields();
      this.emitExecute();
    },
    emitExecute(source = 'url') {
      this.$emit('execute', { contentType: 'image', value: source });
    },
    openFileUpload() {
      this.$refs.fileSelector.click();
    },
    onFileSelect(e) {
      this.tiptapEditor
        .chain()
        .focus()
        .uploadImage({
          file: e.target.files[0],
        })
        .run();

      this.resetFields();
      this.emitExecute('upload');
    },
  },
  acceptedMimes,
};
</script>
<template>
  <gl-dropdown
    v-gl-tooltip
    :aria-label="__('Insert image')"
    :title="__('Insert image')"
    size="small"
    category="tertiary"
    icon="media"
    @hidden="resetFields()"
  >
    <gl-dropdown-form class="gl-px-3!">
      <gl-form-input-group v-model="imgSrc" :placeholder="__('Image URL')">
        <template #append>
          <gl-button variant="confirm" @click="insertImage">{{ __('Insert') }}</gl-button>
        </template>
      </gl-form-input-group>
    </gl-dropdown-form>
    <gl-dropdown-divider />
    <gl-dropdown-item @click="openFileUpload">
      {{ __('Upload image') }}
    </gl-dropdown-item>

    <input
      ref="fileSelector"
      type="file"
      name="content_editor_image"
      :accept="$options.acceptedMimes"
      class="gl-display-none"
      @change="onFileSelect"
    />
  </gl-dropdown>
</template>
