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
    createFile(target, file) {
      const { name } = file;
      const { result } = target;

      this.$emit('create', {
        name: `${this.path ? `${this.path}/` : ''}${name}`,
        type: 'blob',
        content: result,
      });
    },
    readFile(file) {
      const reader = new FileReader();

      reader.addEventListener('load', e => this.createFile(e.target, file), { once: true });
      reader.readAsBinaryString(file);
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
