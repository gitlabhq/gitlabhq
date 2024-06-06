<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { isTextFile } from '~/ide/utils';
import ItemButton from './button.vue';

export default {
  components: {
    ItemButton,
  },
  props: {
    path: {
      type: String,
      required: false,
      default: '',
    },
    showLabel: {
      type: Boolean,
      required: false,
      default: true,
    },
    buttonCssClasses: {
      type: String,
      required: false,
      default: null,
    },
  },
  methods: {
    createFile(target, file) {
      const { name, type: mimeType } = file;
      const encodedContent = target.result.split('base64,')[1];
      const rawContent = encodedContent ? atob(encodedContent) : '';
      const isText = isTextFile({ content: rawContent, mimeType, name });

      const emitCreateEvent = (content) =>
        this.$emit('create', {
          name: `${this.path ? `${this.path}/` : ''}${name}`,
          type: 'blob',
          content,
          rawPath: !isText ? URL.createObjectURL(file) : '',
          mimeType,
        });

      if (isText) {
        const reader = new FileReader();

        reader.addEventListener('load', (e) => emitCreateEvent(e.target.result), { once: true });
        reader.readAsText(file);
      } else {
        emitCreateEvent(rawContent);
      }
    },
    readFile(file) {
      const reader = new FileReader();

      reader.addEventListener('load', (e) => this.createFile(e.target, file), { once: true });
      reader.readAsDataURL(file);
    },
    openFile() {
      Array.from(this.$refs.fileUpload.files).forEach((file) => this.readFile(file));
    },
    startFileUpload() {
      this.$refs.fileUpload.click();
    },
  },
};
</script>

<template>
  <li>
    <item-button
      :class="buttonCssClasses"
      :show-label="showLabel"
      :icon-classes="showLabel ? 'mr-2' : ''"
      :label="__('Upload file')"
      class="gl-flex"
      icon="upload"
      @click="startFileUpload"
    />
    <input
      id="file-upload"
      ref="fileUpload"
      type="file"
      class="hidden"
      multiple
      @change="openFile"
    />
  </li>
</template>
