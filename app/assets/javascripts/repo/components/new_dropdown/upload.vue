<script>
  import { mapActions } from 'vuex';

  export default {
    props: {
      path: {
        type: String,
        required: true,
      },
    },
    methods: {
      ...mapActions([
        'createTempEntry',
      ]),
      createFile(target, file, isText) {
        const { name } = file;
        let { result } = target;

        if (!isText) {
          result = result.split('base64,')[1];
        }

        this.createTempEntry({
          name,
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
