<script>
  import eventHub from '../../event_hub';

  export default {
    props: {
      currentPath: {
        type: String,
        required: true,
      },
    },
    methods: {
      createFile(target, file, isText) {
        const { name } = file;
        const nameWithPath = `${this.currentPath !== '' ? `${this.currentPath}/` : ''}${name}`;
        let { result } = target;

        if (!isText) {
          result = result.split('base64,')[1];
        }

        eventHub.$emit('createNewEntry', {
          name: nameWithPath,
          type: 'blob',
          content: result,
          toggleModal: false,
          base64: !isText,
        }, isText);
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
    },
    mounted() {
      this.$refs.fileUpload.addEventListener('change', this.openFile);
    },
    beforeDestroy() {
      this.$refs.fileUpload.removeEventListener('change', this.openFile);
    },
  };
</script>

<template>
  <label
    role="button"
    class="menu-item"
  >
    {{ __('Upload file') }}
    <input
      id="file-upload"
      type="file"
      class="hidden"
      ref="fileUpload"
    />
  </label>
</template>
