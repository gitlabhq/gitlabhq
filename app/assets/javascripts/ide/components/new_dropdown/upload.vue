<script>
import Icon from '~/vue_shared/components/icon.vue';
import ItemButton from './button.vue';

export default {
  components: {
    Icon,
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
    createFile(target, file, isText) {
      const { name } = file;
      let { result } = target;

      if (!isText) {
        // eslint-disable-next-line prefer-destructuring
        result = result.split('base64,')[1];
      }

      this.$emit('create', {
        name: `${this.path ? `${this.path}/` : ''}${name}`,
        type: 'blob',
        content: result,
        base64: !isText,
      });
    },
    readFile(file) {
      const reader = new FileReader();
      const isText = file.type.match(/text.*/) !== null;

      reader.addEventListener('load', e => this.createFile(e.target, file, isText), { once: true });

      if (isText) {
        reader.readAsText(file);
      } else {
        reader.readAsDataURL(file);
      }
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
