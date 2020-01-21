<script>
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
    isText(content, fileType) {
      const knownBinaryFileTypes = ['image/'];
      const knownTextFileTypes = ['text/'];
      const isKnownBinaryFileType = knownBinaryFileTypes.find(type => fileType.includes(type));
      const isKnownTextFileType = knownTextFileTypes.find(type => fileType.includes(type));
      const asciiRegex = /^[ -~\t\n\r]+$/; // tests whether a string contains ascii characters only (ranges from space to tilde, tabs and new lines)

      if (isKnownBinaryFileType) {
        return false;
      }

      if (isKnownTextFileType) {
        return true;
      }

      // if it's not a known file type, determine the type by evaluating the file contents
      return asciiRegex.test(content);
    },
    createFile(target, file) {
      const { name } = file;
      let { result } = target;
      const encodedContent = result.split('base64,')[1];
      const rawContent = encodedContent ? atob(encodedContent) : '';
      const isText = this.isText(rawContent, file.type);

      result = isText ? rawContent : encodedContent;

      this.$emit('create', {
        name: `${this.path ? `${this.path}/` : ''}${name}`,
        type: 'blob',
        content: result,
        base64: !isText,
        binary: !isText,
        rawPath: !isText ? target.result : '',
      });
    },
    readFile(file) {
      const reader = new FileReader();

      reader.addEventListener('load', e => this.createFile(e.target, file), { once: true });
      reader.readAsDataURL(file);
    },
    openFile() {
      Array.from(this.$refs.fileUpload.files).forEach(file => this.readFile(file));
    },
    startFileUpload() {
      this.$refs.fileUpload.click();
    },
  },
};
</script>

<template>
  <div>
    <item-button
      :class="buttonCssClasses"
      :show-label="showLabel"
      :icon-classes="showLabel ? 'mr-2' : ''"
      :label="__('Upload file')"
      class="d-flex"
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
  </div>
</template>
